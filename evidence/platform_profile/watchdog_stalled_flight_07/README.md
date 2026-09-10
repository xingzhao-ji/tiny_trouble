# Harness smoke — not a performance baseline

Result: **FAIL**. 7.72 seconds in the measured VS01 fixture phase on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

Startup ready: True after 0.22 s; stable native foreground required: False. The normal Start/Resume commands run once before warmup; production lifecycle remains enabled. Watchdog outcome: stationary_flight. Active sampling started: True.

App version 0.2.3; native None window, logical viewport (1280.0, 1280.0), cap 60, VSync mode None, reported refresh None Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 2.01 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 120 frames with walking and actual position change, 0 with flight and actual position change, and 0 completed flights. Measurement continues the current motion at the phase boundary when validation succeeds.

Measured workload: 322 walking-motion frames, 0 flight-motion frames, 0 completed flights and 0 paused frames. Stale walking/flying flags alone do not count as movement. Per-second watchdog samples retain transforms, flight clock, pause/focus state and held movement actions in both phases.

Process-frame wall intervals: p50 **16.662 ms**, p95 **19.388 ms**, p99 **20.526 ms**, maximum **23.572 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 0; rendered objects: 0.

Active-period external RSS peak: **129.1 MiB**. Active process CPU interval p50/p95: 2.0% / 3.0% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 129.1 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–10.0 s | 462 | 16.662 | 19.388 | 20.526 | 0 |
| 10–18.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |

Collector frame storage: 1,200 preallocated slots, **20,400 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 19,908 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 26.2 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 88.312 | 95.310 |

Injected input → changed render-state observation: 0/9 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).

Run issues:

- Engine exited with code 1.
- No passing runtime profile report was produced.
- Workload watchdog: stationary_flight
