# Harness smoke — not a performance baseline

Result: **PASS**. 3.02 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

App version 0.2.3; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 2.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 120 walking frames, 0 flight frames and 0 completed flights. Measurement continues the current motion at the phase boundary.

Process-frame wall intervals: p50 **16.650 ms**, p95 **16.954 ms**, p99 **21.031 ms**, maximum **21.200 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 478; rendered objects: 768.

Active-period external RSS peak: **239.8 MiB**. Active process CPU interval p50/p95: 43.5% / 43.5% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 246.2 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–3.0 s | 181 | 16.650 | 16.954 | 21.031 | 0 |

Collector frame storage: 300 preallocated slots, **5,100 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 1,852 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 25.9 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 94.210 | 573.117 |
| W01S01 | 64.286 | 320.854 |
| W01S02 | 82.019 | 187.302 |
| W01S03 | 68.972 | 169.475 |

Injected input → changed render-state observation: 0/0 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
