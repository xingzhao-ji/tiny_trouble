# Aborted native profile — no valid baseline

Result: **FAIL**. 106.99 seconds in the measured VS01 fixture phase on Apple M4 Pro / Mac16,7. This run failed workload validation. Retained timings are diagnostics and do not establish an active gameplay baseline.

Startup ready: True after 0.81 s; stable native foreground required: True. The normal Start/Resume commands run once before warmup; production lifecycle remains enabled. Watchdog outcome: native_focus_lost. Active sampling started: True.

App version 0.2.6; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 60.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 2208 frames with walking and actual position change, 794 with flight and actual position change, and 4 completed flights. Measurement continues the current motion at the phase boundary when validation succeeds.

Measured workload: 3795 walking-motion frames, 1624 flight-motion frames, 9 completed flights and 0 paused frames. Stale walking/flying flags alone do not count as movement. Per-second watchdog samples retain transforms, flight clock, pause/focus state and held movement actions in both phases.

Process-frame wall intervals: p50 **16.647 ms**, p95 **17.170 ms**, p99 **19.025 ms**, maximum **30.036 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 516; rendered objects: 758.

Active-period external RSS peak: **241.0 MiB**. Active process CPU interval p50/p95: 26.5% / 28.5% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 241.0 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–10.0 s | 600 | 16.645 | 17.182 | 17.801 | 600 |
| 10–20.0 s | 599 | 16.649 | 17.171 | 17.762 | 599 |
| 20–30.0 s | 600 | 16.648 | 17.213 | 20.590 | 600 |
| 30–40.0 s | 601 | 16.648 | 17.202 | 19.985 | 601 |
| 40–50.0 s | 600 | 16.650 | 17.133 | 19.363 | 600 |
| 50–60.0 s | 599 | 16.643 | 17.175 | 17.508 | 599 |
| 60–70.0 s | 601 | 16.659 | 17.142 | 20.598 | 601 |
| 70–80.0 s | 600 | 16.646 | 17.173 | 19.735 | 600 |
| 80–90.0 s | 599 | 16.644 | 17.148 | 18.765 | 599 |
| 90–100.0 s | 599 | 16.651 | 17.205 | 19.550 | 599 |
| 100–110.0 s | 419 | 16.637 | 17.199 | 17.443 | 419 |
| 110–120.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 120–130.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 130–140.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 140–150.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 150–160.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 160–170.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 170–180.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 180–190.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 190–200.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 200–210.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 210–220.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 220–230.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 230–240.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 240–250.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 250–260.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 260–270.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 270–280.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 280–290.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 290–300.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 300–310.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 310–320.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 320–330.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 330–340.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 340–350.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 350–360.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 360–370.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 370–380.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 380–390.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 390–400.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 400–410.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 410–420.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 420–430.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 430–440.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 440–450.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 450–460.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 460–470.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 470–480.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 480–490.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 490–500.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 500–510.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 510–520.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 520–530.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 530–540.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 540–550.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 550–560.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 560–570.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 570–580.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 580–590.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |
| 590–600.0 s | 0 | 0.000 | 0.000 | 0.000 | 0 |

Collector frame storage: 36,120 preallocated slots, **614,040 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 267,832 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 27.2 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 96.234 | 572.832 |

Injected input → changed render-state observation: 85/85 probes changed an on-screen target, p50 17.119 ms / p95 33.384 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).

Run issues:

- Engine exited with code 1.
- No passing runtime profile report was produced.
- Workload watchdog: native_focus_lost
- Requested continuous active sampling duration was not reached.
