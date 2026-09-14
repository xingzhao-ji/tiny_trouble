from pathlib import Path
import subprocess,json,hashlib,shutil
root=Path('/Users/xingzhaoji/Desktop/mine/tiny_trouble');base=root/'evidence/release_media_027'
exe=Path.home()/'Library/Application Support/TinyTrouble/SteamStaging/0.2.7-20260914/content/macos/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express'
for name,script in [('crumb','tests/chapter/replay_crumb.gd'),('ballast','tests/chapter/replay_ballast.gd'),('demo','tests/replay_export.gd')]:
    folder=base/name;folder.mkdir(exist_ok=False)
    with (folder/'engine.log').open('w') as log: r=subprocess.run([str(exe),'--path',str(root),'--resolution','1920x1080','--write-movie',str(folder/'movie.avi'),'--fixed-fps','60','--script',str(root/script),'--',f'--evidence-dir={folder}','--evidence-mode=movie','--evidence-fixed-fps=60'],cwd=root,stdout=log,stderr=subprocess.STDOUT,timeout=150)
    text=(folder/'engine.log').read_text();assert r.returncode==0 and 'ERROR:' not in text and 'FAIL' not in text,text[-2000:]
    print(name,'captured',flush=True)
shutil.copy2('/tmp/tiny-027-harbor-movie.log',base/'harbor/engine.log')
manifest=json.loads((root/'builds/release-0.2.7-20260914/manifest.json').read_text())
records=[]
for name in ['crumb','ballast','harbor','demo']:
    folder=base/name;raw=folder/'movie.avi';mp4=folder/'route.mp4'
    before=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,width,height,nb_frames','-show_entries','format=duration,size','-of','json',str(raw)],text=True))
    assert before['streams'][0]['width']==1920 and before['streams'][0]['height']==1080
    subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-c:v','libx264','-crf','21','-preset','medium','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(mp4)],check=True)
    after=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,width,height,nb_frames','-show_entries','format=duration,size','-of','json',str(mp4)],text=True))
    assert after['streams'][0]['width']==1920 and after['streams'][0]['height']==1080 and before['streams'][0]['nb_frames']==after['streams'][0]['nb_frames']
    subprocess.run(['ffmpeg','-v','error','-i',str(mp4),'-f','null','-'],check=True)
    record={'route':name,'raw':before,'encoded':after,'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'mp4_sha256':hashlib.sha256(mp4.read_bytes()).hexdigest(),'raw_removed_after_verification':True,'result':json.loads((folder/'replay_report.json').read_text())['result']}
    records.append(record);assert record['result']=='PASS';raw.unlink();print(name,'encoded, decoded and raw hash preserved',flush=True)
    for sidecar in folder.glob('movie.avi.wav'): sidecar.unlink()
(base/'manifest.json').write_text(json.dumps({'version':manifest['version'],'source':manifest['source_sha256'],'mac_archive_sha256':manifest['macos']['sha256'],'executable_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'method':'Actual exported app; generated ordinary gameplay inputs. Only prerequisite stages are seeded for the chapter routes. Fixed60FPS MovieMaker recording is not real-time performance or human pacing.','routes':records},indent=2)+'\n')
shutil.copy2('/tmp/capture-tiny-preview.py',base/'capture-runner.py')
