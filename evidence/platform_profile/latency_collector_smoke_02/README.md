# Harness smoke — not a performance baseline

Result: **PASS**. 4.02 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

Stable app version 0.2.2; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Process-frame wall intervals: p50 **16.665 ms**, p95 **17.517 ms**, p99 **18.255 ms**, maximum **18.441 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 452; rendered objects: 676.

Active-period external RSS peak: **228.0 MiB**. Active process CPU interval p50/p95: 30.5% / 33.4% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 239.1 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–4.0 s | 240 | 16.665 | 17.517 | 18.255 | 0 |

Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 86.980 | 556.671 |
| W01S01 | 58.997 | 305.692 |
| W01S02 | 65.835 | 161.298 |
| W01S03 | 54.308 | 148.089 |

Injected input → changed render-state observation: 4/4 probes changed an on-screen target, p50 23.174 ms / p95 24.374 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
