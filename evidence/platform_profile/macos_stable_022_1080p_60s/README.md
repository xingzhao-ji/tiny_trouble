# Native macOS runtime baseline

Result: **PASS**. 60.02 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. This is a measurement of this host only.

Stable app version 0.2.2; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Process-frame wall intervals: p50 **16.644 ms**, p95 **17.144 ms**, p99 **18.700 ms**, maximum **33.048 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 516; rendered objects: 758.

Active-period external RSS peak: **236.3 MiB**. Active process CPU interval p50/p95: 36.4% / 38.3% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 243.0 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–10.0 s | 599 | 16.644 | 17.316 | 18.700 | 599 |
| 10–20.0 s | 600 | 16.643 | 17.106 | 17.337 | 600 |
| 20–30.0 s | 599 | 16.646 | 17.142 | 18.450 | 599 |
| 30–40.0 s | 600 | 16.642 | 17.106 | 19.660 | 600 |
| 40–50.0 s | 600 | 16.642 | 17.121 | 21.216 | 600 |
| 50–60.0 s | 600 | 16.644 | 17.113 | 19.303 | 600 |

Active-period process memory and CPU over time (external one-second samples):

| Active interval | RSS first MiB | RSS last MiB | RSS peak MiB | CPU median % |
| --- | ---: | ---: | ---: | ---: |
| 0–10 s | 232.1 | 234.0 | 234.1 | 35.4 |
| 10–20 s | 234.0 | 234.6 | 234.9 | 36.4 |
| 20–30 s | 234.9 | 235.3 | 235.9 | 35.3 |
| 30–40 s | 235.2 | 235.7 | 236.3 | 36.4 |
| 40–50 s | 235.8 | 235.7 | 235.8 | 37.3 |
| 50–60 s | 236.2 | 235.9 | 236.2 | 37.3 |

RSS starts near 232 MiB and ends near 236 MiB during this short run; cached assets, transient objects, and retained profiler samples all contribute. This is not a long-session leak test. Engine render-memory estimates remained around 93 MiB; release static allocator counters returned unavailable.

Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 88.148 | 566.100 |
| W01S01 | 59.406 | 303.914 |
| W01S02 | 66.518 | 160.491 |
| W01S03 | 53.064 | 145.531 |

Injected input → changed render-state observation: 45/50 probes changed an on-screen target, p50 16.723 ms / p95 33.242 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized. The five unobserved probes were jump probes superseded by the following movement probe in the original harness; their latency is censored, not a game-input failure. The 45 observed samples remain unchanged. Recorded process-frame differences are engine counter deltas, not physical display-frame counts.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
