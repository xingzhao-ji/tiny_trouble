#!/usr/bin/env python3
"""Post-run analysis only. Reads frozen samples; writes a separate derived review."""
import argparse
import collections
import csv
import hashlib
import json
import math
from pathlib import Path

MIB = 1048576

def summary(values):
    values = sorted(v for v in values if v is not None and math.isfinite(v))
    if not values:
        return {'samples': 0}
    n = len(values)
    return {'samples': n, 'min': values[0], **{f'p{p}': values[min(n-1, int(n*p/100))] for p in [50,95,99]}, 'max': values[-1]}

def frames_summary(rows):
    return {'frame_ms': summary([r['ms'] for r in rows]), 'summed_interval_seconds': sum(r['ms'] for r in rows)/1000,
            'threshold_counts': {str(t): sum(r['ms'] > t for r in rows) for t in [16.666667,20,25,33.333333,50,100]},
            'fixture_transition_frames': sum(r['fixture'] for r in rows),
            'walking_frames': sum(r['walking'] for r in rows), 'flying_frames': sum(r['flying'] for r in rows)}

def slope_per_minute(pairs):
    if len(pairs) < 2: return None
    x = sum(p[0] for p in pairs)/len(pairs)
    y = sum(p[1] for p in pairs)/len(pairs)
    den = sum((p[0]-x)**2 for p in pairs)
    return sum((p[0]-x)*(p[1]-y) for p in pairs)/den*60 if den else None

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    args = parser.parse_args()
    folder = args.folder.resolve()
    raw_paths = [folder/p for p in ['profile_report.json','runtime_profile.json','process_frames.csv','process_samples.json','harness_at_measurement.gd','sampler_at_measurement.py','engine.log','operator_events.json']]
    for p in raw_paths:
        if not p.is_file(): parser.error('Completed raw input missing: '+p.name)
    report = json.loads((folder/'profile_report.json').read_text())
    rt = report['runtime']
    if report['engine_exit_code'] is None: parser.error('Engine completion is not recorded.')
    raw_hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in raw_paths}
    out = folder/'post_run_review'
    out.mkdir(exist_ok=True)
    rows = []
    with (folder/'process_frames.csv').open() as f:
        for r in csv.DictReader(f):
            rows.append({'t':float(r['active_seconds']), 'ms':float(r['process_frame_ms']),
                         'focused':r['window_focused'].lower()=='true', 'fixture':r['fixture_transition'].lower()=='true',
                         'walking':r['walking'].lower()=='true', 'flying':r['flying'].lower()=='true'})
    assert len(rows)==rt['process_frame_ms']['samples']
    all_process = json.loads((folder/'process_samples.json').read_text())
    start,end = rt['active_start_unix_seconds'],rt['active_end_unix_seconds']
    process = [{**p,'t':p['unix_time_seconds']-start,'rss_mib':p['rss_bytes']/MIB} for p in all_process if start<=p['unix_time_seconds']<=end]
    duration = rt['active_wall_seconds']
    split = {label:frames_summary([r for r in rows if r['focused']==flag]) for label,flag in [('focused',True),('unfocused',False)]}
    segments=[]
    for r in rows:
        if not segments or segments[-1]['focused']!=r['focused']:
            segments.append({'focused':r['focused'],'start_seconds':max(0,r['t']-r['ms']/1000),'rows':[]})
        segments[-1]['rows'].append(r)
        segments[-1]['end_seconds']=r['t']
    segment_summary=[]
    for seg in segments:
        x={k:v for k,v in seg.items() if k!='rows'}
        x['statistics']=frames_summary(seg['rows'])
        segment_summary.append(x)
    windows=[]
    for label,lo,hi in [('first_120_active_seconds',0,120),('last_120_active_seconds',max(0,duration-120),duration+0.001)]:
        selected=[r for r in rows if lo<=r['t']<hi]
        rss=[p['rss_mib'] for p in process if lo<=p['t']<hi]
        windows.append({'label':label,'start_seconds':lo,'end_seconds':hi,'all':frames_summary(selected),
                        'focused':frames_summary([r for r in selected if r['focused']]),
                        'unfocused':frames_summary([r for r in selected if not r['focused']]),'rss_mib':summary(rss)})
    buckets=[]
    for lo in range(0,math.ceil(rt['duration_requested_seconds']),10):
        hi = duration+0.001 if lo+10 >= rt['duration_requested_seconds'] else lo+10
        sel=[r for r in rows if lo<=r['t']<hi]
        buckets.append({'start_seconds':lo,'end_seconds':min(lo+10,duration),'all':frames_summary(sel),
                        'focused':frames_summary([r for r in sel if r['focused']]),
                        'unfocused':frames_summary([r for r in sel if not r['focused']]),
                        'rss_mib':summary([p['rss_mib'] for p in process if lo<=p['t']<lo+10])})
    rolling=[]
    for lo in range(0,max(0,math.ceil(duration)-119),10):
        sel=[r for r in rows if lo<=r['t']<lo+120]
        rolling.append({'start_seconds':lo,'end_seconds':lo+120,'focused':frames_summary([r for r in sel if r['focused']]),
                        'unfocused':frames_summary([r for r in sel if not r['focused']])})
    probes=rt['input_response_samples']
    probe_groups={}
    for label in sorted(set(p['label'] for p in probes)):
        selected=[p for p in probes if p['label']==label]
        valid=[p for p in selected if p['changed_render_state_observed'] and p['target_in_viewport']]
        probe_groups[label]={'total':len(selected),'valid_on_screen':len(valid),'elapsed_ms':summary([p['elapsed_ms'] for p in valid]),
                             'focused_ms':summary([p['elapsed_ms'] for p in valid if p['window_focused']]),
                             'unfocused_ms':summary([p['elapsed_ms'] for p in valid if not p['window_focused']]),
                             'status_counts':dict(collections.Counter(p['observation_status'] for p in selected)),
                             'offscreen_changed':sum(p['changed_render_state_observed'] and not p['target_in_viewport'] for p in selected),
                             'process_frame_difference':summary([p['process_frame_difference'] for p in valid])}
    monitors=rt['monitor_samples']
    monitor_stats={k:summary([p.get(k) for p in monitors]) for k in ['fps_monitor','nodes','resources','render_video_bytes','render_texture_bytes','render_buffer_bytes','static_allocator_bytes','process_interval_peak_ms','physics_interval_peak_ms']}
    rss={'samples':len(process),'mib':summary([p['rss_mib'] for p in process]),
         'first_mib':process[0]['rss_mib'],'last_mib':process[-1]['rss_mib'],
         'end_minus_start_mib':process[-1]['rss_mib']-process[0]['rss_mib'],
         'ols_mib_per_minute':slope_per_minute([(p['t'],p['rss_mib']) for p in process]),
         'first_last_120s_median_delta_mib':windows[-1]['rss_mib'].get('p50',0)-windows[0]['rss_mib'].get('p50',0),
         'whole_process_peak_mib':report['external_process']['rss_bytes']['max']/MIB,
         'collector':rt['collector_memory'],'external_python_sampler':report.get('external_sampler'),
         'note':'No collector-memory subtraction. Preallocated packed capacity is before warmup; growing diagnostic serialized bytes are not allocated RAM. Later loads/serialization are outside active sampling.'}
    result={'raw_result':report['result'],'engine_exit_code':report['engine_exit_code'],'raw_issues':report['issues'],'runtime_failures':rt['failures'],'workload_valid':not rt['failures'],
            'active_seconds':duration,'warmup':rt['warmup'],'conditions':rt['conditions'],'workload':rt['workload'],
            'all':frames_summary(rows),'focus_split':split,'focus_segments':segment_summary,
            'first_last_windows':windows,'ten_second_buckets':buckets,'rolling_120s_by_10s':rolling,
            'long_stalls_over_50ms':[r for r in rows if r['ms']>50],
            'largest_20_intervals':sorted(rows,key=lambda r:r['ms'],reverse=True)[:20],
            'rss':rss,'active_cpu_percent':report['external_process']['active_interval_cpu_percent'],
            'monitor_statistics':monitor_stats,'scene_loads':rt['scene_loads'],'response_groups':probe_groups,
            'raw_sha256':raw_hashes,'review_script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'quantile_method':'Sort ascending; select min(n-1,floor(n*p)), matching frozen collector.',
            'limitations':['Focus classified at callback endpoint; a crossing interval can span two focus states.',
              'Focus segments/first-last windows differ in workload phase; not a causal focus experiment.',
              'Prepared VS01 traversal with explicit resets; not whole-campaign or ordinary first play.',
              'Frame intervals include VSync/cap waits and ordinary I/O, not isolated CPU or GPU cost.',
              'Response probes end at changed transform on render-post-draw; no pixel readback or physical input-to-photon timing.',
              'Thermal sensors, GPU timing/power, battery and other hardware remain unmeasured.'],
            'rendering_resource_recommendation':'No renderer/resource reduction is justified by this failed workload. Correct collector foreground/pause/progress validation, prove complete repeated traversal, then rerun. RSS growth is not a leak finding or a thermal result.'}
    (out/'analysis.json').write_text(json.dumps(result,indent=2)+'\n')
    with (out/'plot_buckets.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['seconds','p50','p95','p99','max','focused_fraction'])
        for b in buckets:
            st=b['all']['frame_ms'];n=st['samples']
            if n:w.writerow([b['start_seconds']+5,st['p50'],st['p95'],st['p99'],st['max'],b['focused']['frame_ms']['samples']/n])
    with (out/'plot_rss.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['seconds','rss_mib'])
        for p in process:w.writerow([p['t'],p['rss_mib']])
    with (out/'plot_focus.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['start','end','focused'])
        for seg in segment_summary:w.writerow([seg['start_seconds'],seg['end_seconds'],int(seg['focused'])])
    # Read-only guarantee on original report and all source samples.
    assert raw_hashes=={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in raw_paths}
    print(json.dumps({'output':str(out),'raw_result':report['result'],'frames':len(rows),'focus_split':split,'windows':windows,'rss':{k:v for k,v in rss.items() if k not in ['collector','external_python_sampler']},'monitors':monitor_stats,'responses':probe_groups},indent=2))

if __name__=='__main__': main()
