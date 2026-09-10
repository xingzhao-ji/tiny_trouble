# Frozen 0.2.3 sustained profile · failed workload

**The sustained gameplay gate failed. No rendering/resource reduction is justified by this run.** The engine exited 1 after the requested 120-second warmup and 1,200-second measurement. The measured period contains **zero walking frames, zero completed flights, zero fixture resets and zero response probes**. Every one of its 71,963 interval records has the flight flag set. Frame pacing and RSS describe this stalled scene, not a representative active gameplay workload.

Warmup already had zero completed flights, with 6,635 flight-flagged frames, 440 walking frames and 681 focused frames out of 7,182 total. A focus-loss pause stranding the first flight is a strong inference: production interruption handling pauses gameplay, and foreground return deliberately requires explicit resume. The raw collector did not record `paused`, flight-time progression or transforms, so this review does not treat that cause as proven. The required workload assertion correctly rejected the run; its late detection allowed an invalid workload to consume the full duration. The next collector needs bounded foreground/readiness, direct pause/progress checks, warmup completion evidence and a fail-fast stalled-flight check while preserving production lifecycle behavior.

## Diagnostic measurements

Native Apple M4 Pro, macOS 26.6.2, 48 GiB RAM; actual 0.2.3 Mac package at 1920×1080 with logical 1280×720, cap 60, VSync enabled, reported 120 Hz, AC power. No movie/PNG capture occurred during measurement. The harness requested ordinary audio/save work, but their continued activity during the inferred pause was not measured.

| Interval group | Frames | Summed interval seconds | p50 / p95 / p99 ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: |
| All callbacks | 71,963 | 1,200.001 | 16.637 / 17.200 / 17.556 | 31.421 |
| Focused endpoints | 39,781 | 663.048 | 16.635 / 17.165 / 17.395 | 31.421 |
| Unfocused endpoints | 32,182 | 536.953 | 16.640 / 17.261 / 18.036 | 30.764 |
| First 120 seconds, all unfocused | 7,177 | 120.000 | 16.647 / 17.383 / 19.470 | 30.764 |
| Last 120 seconds, all focused | 7,201 | 120.017 | 16.633 / 17.153 / 17.351 | 29.804 |

Focus is classified at each callback endpoint; a crossing interval can span two focus states. The complete ten-segment timeline is in `analysis.json`. The principal unfocused spans were 0–156.967 and 194.983–544.136 measured seconds. Focused spans were 544.136–836.283 and 840.083–1,200.001 seconds, with brief earlier changes. The recorded operator activation occurred at approximately **544.306 measured seconds** (the operator's earlier estimate used process elapsed time). This is not twenty minutes continuously foreground, and first/last differences are not a causal focus or thermal comparison.

The first 0–10-second bucket has p50/p95/p99 **16.643/17.422/19.681 ms**; the final 1,190–1,200-second bucket has **16.631/17.141/17.277 ms**. Ten-second overall p99 values range from **17.277 to 22.319 ms**. Within the final continuous focused segment, its first and last two-minute windows have p99 **17.371 and 17.351 ms**. These diagnostic windows show no worsening of this stalled scene's frame distribution; they do not establish active workload sustainability.

There are **344 intervals over 20 ms**, **223 over 25 ms**, and **none over 33.333, 50 or 100 ms**. The largest is 31.421 ms at 194.015 seconds, close to a focus transition; coincidence does not establish its cause. All fixture-transition flags are false. Cap/VSync waits, application/OS scheduling and ordinary I/O are included; these are not isolated CPU/GPU timings. Peak reported draws/objects are **475/770**. FPS monitor range is 59–61 with p50 60.

## Memory, loads and responses

Active game RSS rises from **241.016 to 243.469 MiB**, a **2.453 MiB** increase over 1,186 samples. The first/last two-minute medians rise **2.266 MiB**; the descriptive linear slope is **0.125 MiB/minute**. Whole-process peak is **248.438 MiB**, including later scene loads and report serialization. Active process CPU p50/p95 is **28.6%/41.4%**, where 100% means one logical CPU.

The frame store reserves **1,226,040 packed payload bytes before warmup**. During measurement the collector accumulates **1,189 monitor dictionaries**, whose combined diagnostic serialization is **724,024 bytes**; there are no event/probe records. Serialized size is not allocated RAM, and container/allocator overhead is unmeasured. The separate Python sampler peaks at **29.578 MiB** and is excluded from game RSS. Current production source also has a bounded 60,000-entry frame-sample array, but its paused guard prevents assigning this run's growth to it without direct state evidence. No overhead subtraction or leak claim is made.

Reported node/resource counts remain **306/21** throughout. Render-buffer memory stays **8,148,740 bytes**; render-video/texture estimates each change by only **4,428 bytes**. Those stable counts do not prove absence of leaks, but this modest RSS trend with retained diagnostics is insufficient evidence for a game resource defect. Static allocator counters are unavailable in the release export.

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 94.638 | 570.804 |
| Crumb Crossing | 58.500 | 303.935 |
| Blueberry Ballast | 69.100 | 163.604 |
| Milk Harbor | 54.040 | 147.225 |

These are one in-process readiness observation per scene, outside the measurement interval, with shared resources/OS caches potentially warm. They exclude process startup, are not cold-launch distributions and do not establish pixel-visible readiness. **There are no response samples**, so no input-response quantile can be reported. Future probes end at a changed transform on render-post-draw, not physical input-to-photon latency.

The `pmset` strings say no warning/status was recorded; they provide no measured temperature, power, throttle history or thermal success. GPU timing/power, battery life, physical input and other hardware remain unmeasured.

## Decision and reproducibility

Fix the collector's workload/foreground validation, prove several complete warmup and measured flights in a bounded run, then repeat the declared sustained gate. Keep production pause/resume behavior intact. Maintain the current rendering defaults until valid workload evidence identifies a bottleneck. Audio-pool/source presentation changes are separate pending work and do not convert this frozen result into a pass. Stable 0.2.2 remains preserved.

[Frame-time/RSS plot](frame_time_rss.png) uses base R graphics; shaded spans are unfocused. Every 10-second maximum is shown, and all source intervals remain in the raw CSV. `analysis.json` contains split-focus summaries, complete segments, 10-second buckets, rolling 120-second windows, stalls, memory, loads and empty response groups. `verification.json` hashes the frozen inputs and derived artifacts. No original report, CSV, log or collector snapshot was edited.

From the project root:

```sh
python3 evidence/platform_profile/review_sustained.py evidence/platform_profile/macos_candidate_023_1080p_20m
Rscript evidence/platform_profile/plot_sustained.R evidence/platform_profile/macos_candidate_023_1080p_20m/post_run_review
```

The scripts reproduce numeric analysis and the plot. This narrative records the bounded interpretation; a newer successful run must use a distinct evidence directory.
