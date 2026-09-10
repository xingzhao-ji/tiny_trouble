# Harness smoke — not a performance baseline

Result: **FAIL**. 0.00 seconds in the measured VS01 fixture phase on Apple M4 Pro / Mac16,7. Harness validation only; these timings do not establish native performance.

Startup ready: True after 0.22 s; stable native foreground required: False. The normal Start/Resume commands run once before warmup; production lifecycle remains enabled. Watchdog outcome: production_paused. Active sampling started: False.

App version 0.2.3; native None window, logical viewport None, cap None, VSync mode None, reported refresh None Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 1.53 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 60 frames with walking and actual position change, 0 with flight and actual position change, and 0 completed flights. Measurement continues the current motion at the phase boundary when validation succeeds.

Measured workload: 0 walking-motion frames, 0 flight-motion frames, 0 completed flights and 0 paused frames. Stale walking/flying flags alone do not count as movement. Per-second watchdog samples retain transforms, flight clock, pause/focus state and held movement actions in both phases.

Process-frame wall intervals: p50 **0.000 ms**, p95 **0.000 ms**, p99 **0.000 ms**, maximum **0.000 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 0; rendered objects: 0.

Active-period external RSS peak: **0.0 MiB**. Active process CPU interval p50/p95: 0.0% / 0.0% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 129.5 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–3.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |

Collector frame storage: 300 preallocated slots, **5,100 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 1,884 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 26.0 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 88.224 | 95.211 |

Injected input → changed render-state observation: 0/0 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).

Run issues:

- Engine exited with code 1.
- No passing runtime profile report was produced.
- Workload watchdog: production_paused
- Requested active warmup duration was not reached.
