# Prospective review: 0.2.6 ten-minute demo profile

Recorded UTC: **2026-09-10T04:57:05.482700+00:00**. Saved during the announced 60-second warmup, after root reported launching the run. This reviewer has not opened or sampled any files from the new run. These criteria derive from the already-reviewed 0.2.5 120-second evidence and the previously declared 60 FPS reference-machine target; no new-run outcome informed them.

Planned evidence: `macos_candidate_026_1080p_10m/`. Preserve the prior 0.2.5 short run and failed 0.2.3 long attempt separately. This plan changes neither collector nor runtime.

## Exact scope and conditions

The active scene is **VS01, the original Toast Express demo**. The harness seeds a legal prepared launch state and initial position, then uses production movement/input, resize, boarding, flight, animation, audio and saves. Completion/reset repetitions are explicit fixtures. They are not ordinary-player completion, human responsiveness, enjoyment or campaign validation.

Require **60 seconds of the same active fixture for warmup, then 600 measured seconds**, with no reset solely at the phase boundary. Record the actual 0.2.6 executable/PCK hashes and archived collector, Apple M4 Pro/reference host, 1920×1080 native window, 1280×720 logical viewport, 60 FPS cap, VSync/refresh, AC power and normal audio/save conditions. No screenshots, Movie Maker/fixed-FPS mode, competing engine/export/encode jobs or automatic lifecycle bypass during measurement. Background OS activity is not eliminated by agent coordination.

Crumb Crossing, Blueberry Ballast and Milk Harbor are only **separate load-to-ready/first-render title probes after the measured demo loop**. They do not provide sustained chapter gameplay timings. Load figures exclude process startup; shared assets and OS/shader caches may be warm. Do not label them cold-start, cold-disk or cold-shader results. Workshop is not the active workload either.

## Workload validity — required before interpreting performance

- Collector and external sampler agree on schema, package identity and successful exit; inspect full logs for errors, watchdog aborts, leaks and retained resources. Preserve failure as failure rather than discarding an interrupted section.
- Requested and observed intervals cover the full 60-second active warmup and 600-second measured phase. Startup reaches native focus readiness, and the normal Start/Resume path is used once. Every measured CSV interval must be focused and unpaused. Check warmup focus totals and all available progress samples too; do not infer unsampled pause state.
- Watchdog remains clear. CSV timestamps/counts and retained-buffer capacity must be consistent; inspect actual position-change flags and progress transforms/flight clock, rather than accepting `walking`/`flying` booleans alone.
- Every measured minute must contain actual walking and flight motion and continuing fixture resets. Enumerate contiguous flight segments and their endings over time, compare them with reset timestamps and the aggregate completed-flight counter, and explain phase-boundary partial segments. The collector does not directly timestamp every completion, so do not invent per-minute completion counts when the available evidence cannot establish them.
- The prior run reset about every **12.52 seconds**, with 10 completed flights in 120 seconds. Approximately **48–50 completed flights** over ten minutes is an expected fixture cadence, not an arbitrary release quota or player-performance target. Investigate missing progress in any minute or materially changed cadence, even if aggregate counters pass the collector's minimal checks.
- Retain all injected render-state response probes. Report changed/failed/censored observations; a probe cut off at measurement end is not physical latency or automatically a runtime defect.

## Frame pacing over time

Compute p50/p95/p99/max and slow-frame counts **for each minute**, alongside the retained ten-second buckets and whole-run distribution. Count intervals above **20, 25, 33.333, 50 and 100 ms**. These are descriptive diagnostic bands around the 16.667 ms/60 FPS target, not a new universal acceptance standard. Keep fixture reset/save intervals in primary statistics; secondary comparisons may identify them explicitly, never silently remove them.

Compare the first and last 60 seconds and inspect intermediate minutes for sustained deterioration or clusters hidden by an overall percentile. The 0.2.5 reference had p50/p95/p99 **16.642/17.162/19.084 ms**, max **30.039 ms**; 61 intervals above20 ms, 20 above25 ms, and none above33.333 ms. First/last-minute p95 was17.161/17.162 ms and p99 was19.266/19.287 ms. Differences outside that short reference envelope trigger investigation of workload/event/CPU conditions; one spike alone does not justify renderer degradation. Report the observed pacing and its limits rather than inventing a beauty or human-satisfaction score.

## Memory and scene-count review

Use only process RSS samples timestamped within the active interval. Compare the **median/min/max for seconds0–60 and540–600**, their median difference in MiB and percent, and all intermediate minute envelopes. Also retain individual first/last samples, active peak and whole-process peak separately; later scene loads/postprocessing must not be mistaken for active growth.

The short reference's first/last-minute RSS medians were **238.234/238.898 MiB** (+0.664 MiB), individual endpoints differed by1.000 MiB, and active peak was239.844 MiB. Node counts repeatedly ranged305–337 and resources remained21; changing effects/menu nodes are not automatically leaks. Compare equivalent repeated phases and look for a rising floor or persistent resource growth, rather than demanding an identical last node count.

The ten-minute collector preallocates36,120 slots = **614,040 exact packed payload bytes** before warmup at the60 FPS cap. Monitor/probe/watchdog dictionaries accumulate; serialized byte counts are not allocated RAM. Report those counts and the separate Python sampler RSS, with no speculative overhead subtraction. Continued RSS growth should lead to allocation-focused follow-up and matched-phase comparisons; neither a flat RSS graph nor an arbitrary memory threshold establishes leak freedom or releases the game.

A valid result supports only this bounded ten-minute **demo fixture on this host and configuration**. Thermal state, component power, battery life, physical touch/controller/input-to-photon latency, other hardware/platforms and sustained performance of the three chapter stages remain unverified. Available sensor values must be reported as unknown where absent.


## Timing correction added after the failed attempt

Correction recorded UTC: **2026-09-10T05:02:15.610094+00:00**. The original introduction incorrectly said this plan was saved during warmup. The completed run records warmup start at **2026-09-10T04:55:36.504350+00:00** and active start at **2026-09-10T04:56:36.521180+00:00**. The plan's unchanged creation timestamp, **2026-09-10T04:57:05.482700+00:00**, is **28.961520 seconds into the active phase**. No files/results from the new run had been inspected when the plan was written; its criteria came from the previous 0.2.5 review. The criteria are unchanged. The original exact bytes are retained as `macos_candidate_026_1080p_10m/post_run_review/PLAN_026_10MIN_original.md`, SHA256 `fda8ba34138350e3ebcf104945a94edb06c03557b403d0ef377cebb2edc10038`. This correction does not convert the interrupted run into a valid ten-minute measurement.
