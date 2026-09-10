# Harness smoke — not a performance baseline

Result: **PASS**. 3.02 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

App version 0.2.2; native None window, logical viewport (1280.0, 720.0), cap 60, VSync mode None, reported refresh None Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 2.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 120 walking frames, 0 flight frames and 0 completed flights. Measurement continues the current motion at the phase boundary.

Process-frame wall intervals: p50 **16.666 ms**, p95 **19.194 ms**, p99 **20.163 ms**, maximum **20.332 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 0; rendered objects: 0.

Active-period external RSS peak: **126.1 MiB**. Active process CPU interval p50/p95: 2.0% / 2.0% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 130.0 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–3.0 s | 181 | 16.666 | 19.194 | 20.163 | 0 |

Collector frame storage: 300 preallocated slots, **5,100 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 3,444 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 25.6 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 83.097 | 90.112 |
| W01S01 | 68.516 | 71.153 |
| W01S02 | 73.914 | 76.944 |
| W01S03 | 67.973 | 70.764 |

Injected input → changed render-state observation: 0/4 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).
