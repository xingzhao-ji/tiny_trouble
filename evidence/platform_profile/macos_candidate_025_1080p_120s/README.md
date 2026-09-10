# Native macOS runtime profile

Result: **PASS**. 120.02 seconds in the measured VS01 fixture phase on Apple M4 Pro / Mac16,7. This is a measurement of this host only.

Startup ready: True after 0.77 s; stable native foreground required: True. The normal Start/Resume commands run once before warmup; production lifecycle remains enabled. Watchdog outcome: no watchdog failure recorded. Active sampling started: True.

App version 0.2.5; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 30.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 1183 frames with walking and actual position change, 372 with flight and actual position change, and 2 completed flights. Measurement continues the current motion at the phase boundary when validation succeeds.

Measured workload: 4122 walking-motion frames, 1860 flight-motion frames, 10 completed flights and 0 paused frames. Stale walking/flying flags alone do not count as movement. Per-second watchdog samples retain transforms, flight clock, pause/focus state and held movement actions in both phases.

Process-frame wall intervals: p50 **16.642 ms**, p95 **17.162 ms**, p99 **19.084 ms**, maximum **30.039 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 516; rendered objects: 758.

Active-period external RSS peak: **239.8 MiB**. Active process CPU interval p50/p95: 28.7% / 30.6% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 244.4 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–10.0 s | 600 | 16.643 | 17.163 | 19.917 | 600 |
| 10–20.0 s | 599 | 16.643 | 17.185 | 18.765 | 599 |
| 20–30.0 s | 600 | 16.642 | 17.170 | 20.636 | 600 |
| 30–40.0 s | 601 | 16.637 | 17.157 | 17.303 | 601 |
| 40–50.0 s | 600 | 16.632 | 17.171 | 18.855 | 600 |
| 50–60.0 s | 600 | 16.642 | 17.151 | 20.666 | 600 |
| 60–70.0 s | 599 | 16.637 | 17.195 | 18.868 | 599 |
| 70–80.0 s | 601 | 16.639 | 17.168 | 17.784 | 601 |
| 80–90.0 s | 600 | 16.654 | 17.124 | 17.620 | 600 |
| 90–100.0 s | 600 | 16.643 | 17.157 | 21.079 | 600 |
| 100–110.0 s | 600 | 16.643 | 17.162 | 20.409 | 600 |
| 110–120.0 s | 600 | 16.637 | 17.188 | 20.259 | 600 |

Collector frame storage: 7,320 preallocated slots, **124,440 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 277,320 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 27.2 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 95.262 | 572.281 |
| W01S01 | 58.667 | 305.271 |
| W01S02 | 66.047 | 174.948 |
| W01S03 | 54.378 | 147.952 |

Injected input → changed render-state observation: 95/95 probes changed an on-screen target, p50 27.639 ms / p95 33.414 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
