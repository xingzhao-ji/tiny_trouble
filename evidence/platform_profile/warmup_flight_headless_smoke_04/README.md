# Harness smoke — not a performance baseline

Result: **PASS**. 4.01 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

App version 0.2.3; native None window, logical viewport (1280.0, 1280.0), cap 60, VSync mode None, reported refresh None Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 15.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 592 walking frames, 187 flight frames and 1 completed flights. Measurement continues the current motion at the phase boundary.

Process-frame wall intervals: p50 **16.645 ms**, p95 **19.190 ms**, p99 **19.962 ms**, maximum **20.383 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 0; rendered objects: 0.

Active-period external RSS peak: **129.2 MiB**. Active process CPU interval p50/p95: 2.9% / 3.0% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 132.3 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–4.0 s | 241 | 16.645 | 19.190 | 19.962 | 0 |

Collector frame storage: 360 preallocated slots, **6,120 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 4,444 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 26.0 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 93.340 | 100.441 |
| W01S01 | 48.185 | 50.975 |
| W01S02 | 61.754 | 65.034 |
| W01S03 | 42.793 | 45.581 |

Injected input → changed render-state observation: 0/5 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
