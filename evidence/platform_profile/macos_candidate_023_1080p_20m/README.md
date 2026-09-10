# Native macOS runtime profile

Result: **FAIL**. 1200.00 seconds of continuous active VS01 fixture sampling on Apple M4 Pro / Mac16,7. This is a measurement of this host only.

App version 0.2.3; native (1920, 1080) window, logical viewport (1280.0, 720.0), cap 60, VSync mode 1, reported refresh 120.0 Hz. Captures disabled; normal audio and game save I/O enabled. Power source: AC Power.

Active warmup: 120.02 s using the same route fixture, excluded from primary frame/CPU/RSS statistics. Warmup included 440 walking frames, 6635 flight frames and 0 completed flights. Measurement continues the current motion at the phase boundary.

Process-frame wall intervals: p50 **16.637 ms**, p95 **17.200 ms**, p99 **17.556 ms**, maximum **31.421 ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: 475; rendered objects: 770.

Active-period external RSS peak: **243.5 MiB**. Active process CPU interval p50/p95: 28.6% / 41.4% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: 248.4 MiB. The raw samples retain timestamps for every phase.

| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0–10.0 s | 597 | 16.643 | 17.422 | 19.681 | 0 |
| 10–20.0 s | 598 | 16.643 | 17.370 | 18.943 | 0 |
| 20–30.0 s | 598 | 16.644 | 17.348 | 19.344 | 0 |
| 30–40.0 s | 600 | 16.644 | 17.284 | 19.486 | 0 |
| 40–50.0 s | 597 | 16.653 | 17.364 | 19.545 | 0 |
| 50–60.0 s | 598 | 16.640 | 17.435 | 19.686 | 0 |
| 60–70.0 s | 599 | 16.653 | 17.425 | 19.726 | 0 |
| 70–80.0 s | 598 | 16.650 | 17.428 | 19.824 | 0 |
| 80–90.0 s | 597 | 16.650 | 17.388 | 18.216 | 0 |
| 90–100.0 s | 598 | 16.647 | 17.400 | 19.983 | 0 |
| 100–110.0 s | 598 | 16.650 | 17.320 | 18.313 | 0 |
| 110–120.0 s | 599 | 16.645 | 17.392 | 19.277 | 0 |
| 120–130.0 s | 597 | 16.645 | 17.287 | 20.915 | 0 |
| 130–140.0 s | 598 | 16.642 | 16.952 | 20.123 | 0 |
| 140–150.0 s | 598 | 16.656 | 17.097 | 20.760 | 0 |
| 150–160.0 s | 599 | 16.655 | 17.211 | 21.768 | 182 |
| 160–170.0 s | 599 | 16.650 | 17.271 | 20.659 | 417 |
| 170–180.0 s | 601 | 16.673 | 17.208 | 19.810 | 0 |
| 180–190.0 s | 599 | 16.649 | 17.431 | 22.319 | 0 |
| 190–200.0 s | 599 | 16.654 | 17.279 | 22.103 | 60 |
| 200–210.0 s | 601 | 16.641 | 17.183 | 17.542 | 0 |
| 210–220.0 s | 599 | 16.636 | 17.156 | 17.541 | 0 |
| 220–230.0 s | 599 | 16.637 | 17.226 | 17.589 | 0 |
| 230–240.0 s | 601 | 16.632 | 17.343 | 17.506 | 0 |
| 240–250.0 s | 599 | 16.630 | 17.152 | 17.402 | 0 |
| 250–260.0 s | 600 | 16.632 | 17.167 | 17.312 | 0 |
| 260–270.0 s | 600 | 16.632 | 17.180 | 17.607 | 0 |
| 270–280.0 s | 600 | 16.638 | 17.158 | 17.772 | 0 |
| 280–290.0 s | 599 | 16.634 | 17.178 | 17.371 | 0 |
| 290–300.0 s | 601 | 16.632 | 17.165 | 17.295 | 0 |
| 300–310.0 s | 600 | 16.634 | 17.162 | 17.434 | 0 |
| 310–320.0 s | 599 | 16.641 | 17.274 | 17.562 | 0 |
| 320–330.0 s | 599 | 16.640 | 17.180 | 17.512 | 0 |
| 330–340.0 s | 600 | 16.634 | 17.153 | 17.445 | 0 |
| 340–350.0 s | 601 | 16.631 | 17.155 | 17.415 | 0 |
| 350–360.0 s | 600 | 16.635 | 17.166 | 17.527 | 0 |
| 360–370.0 s | 599 | 16.634 | 17.198 | 17.490 | 0 |
| 370–380.0 s | 601 | 16.629 | 17.246 | 17.454 | 0 |
| 380–390.0 s | 599 | 16.640 | 17.169 | 17.385 | 0 |
| 390–400.0 s | 601 | 16.634 | 17.178 | 17.466 | 0 |
| 400–410.0 s | 600 | 16.638 | 17.155 | 17.401 | 0 |
| 410–420.0 s | 600 | 16.641 | 17.163 | 17.419 | 0 |
| 420–430.0 s | 599 | 16.630 | 17.291 | 17.493 | 0 |
| 430–440.0 s | 601 | 16.630 | 17.220 | 17.574 | 0 |
| 440–450.0 s | 599 | 16.632 | 17.155 | 17.469 | 0 |
| 450–460.0 s | 601 | 16.636 | 17.146 | 17.523 | 0 |
| 460–470.0 s | 600 | 16.636 | 17.235 | 17.566 | 0 |
| 470–480.0 s | 599 | 16.642 | 17.322 | 17.487 | 0 |
| 480–490.0 s | 600 | 16.636 | 17.346 | 17.603 | 0 |
| 490–500.0 s | 600 | 16.645 | 17.340 | 17.653 | 0 |
| 500–510.0 s | 600 | 16.636 | 17.341 | 17.623 | 0 |
| 510–520.0 s | 601 | 16.643 | 17.321 | 17.607 | 0 |
| 520–530.0 s | 599 | 16.635 | 17.328 | 17.595 | 0 |
| 530–540.0 s | 601 | 16.639 | 17.293 | 17.442 | 0 |
| 540–550.0 s | 600 | 16.636 | 17.205 | 17.579 | 352 |
| 550–560.0 s | 599 | 16.629 | 17.290 | 17.575 | 599 |
| 560–570.0 s | 601 | 16.635 | 17.158 | 17.459 | 601 |
| 570–580.0 s | 600 | 16.632 | 17.187 | 17.699 | 600 |
| 580–590.0 s | 600 | 16.639 | 17.153 | 17.549 | 600 |
| 590–600.0 s | 599 | 16.641 | 17.139 | 17.424 | 599 |
| 600–610.0 s | 600 | 16.627 | 17.233 | 17.426 | 600 |
| 610–620.0 s | 600 | 16.642 | 17.140 | 17.286 | 600 |
| 620–630.0 s | 600 | 16.643 | 17.186 | 17.429 | 600 |
| 630–640.0 s | 600 | 16.637 | 17.180 | 17.397 | 600 |
| 640–650.0 s | 601 | 16.639 | 17.155 | 17.302 | 601 |
| 650–660.0 s | 599 | 16.636 | 17.140 | 17.401 | 599 |
| 660–670.0 s | 600 | 16.640 | 17.157 | 17.537 | 600 |
| 670–680.0 s | 600 | 16.648 | 17.206 | 17.600 | 600 |
| 680–690.0 s | 600 | 16.635 | 17.284 | 17.573 | 600 |
| 690–700.0 s | 600 | 16.637 | 17.191 | 17.576 | 600 |
| 700–710.0 s | 600 | 16.635 | 17.211 | 17.437 | 600 |
| 710–720.0 s | 600 | 16.631 | 17.142 | 17.350 | 600 |
| 720–730.0 s | 600 | 16.629 | 17.177 | 17.405 | 600 |
| 730–740.0 s | 600 | 16.635 | 17.167 | 17.434 | 600 |
| 740–750.0 s | 600 | 16.629 | 17.186 | 17.394 | 600 |
| 750–760.0 s | 600 | 16.637 | 17.147 | 17.372 | 600 |
| 760–770.0 s | 600 | 16.636 | 17.145 | 17.307 | 600 |
| 770–780.0 s | 600 | 16.628 | 17.191 | 17.421 | 600 |
| 780–790.0 s | 600 | 16.632 | 17.144 | 17.405 | 600 |
| 790–800.0 s | 600 | 16.629 | 17.158 | 17.357 | 600 |
| 800–810.0 s | 600 | 16.631 | 17.239 | 17.393 | 600 |
| 810–820.0 s | 600 | 16.634 | 17.166 | 17.300 | 600 |
| 820–830.0 s | 600 | 16.631 | 17.160 | 17.361 | 600 |
| 830–840.0 s | 600 | 16.639 | 17.154 | 17.866 | 378 |
| 840–850.0 s | 600 | 16.637 | 17.298 | 17.717 | 594 |
| 850–860.0 s | 600 | 16.633 | 17.207 | 17.389 | 600 |
| 860–870.0 s | 600 | 16.636 | 17.213 | 17.346 | 600 |
| 870–880.0 s | 600 | 16.637 | 17.160 | 17.335 | 600 |
| 880–890.0 s | 600 | 16.632 | 17.137 | 17.343 | 600 |
| 890–900.0 s | 600 | 16.632 | 17.149 | 17.578 | 600 |
| 900–910.0 s | 599 | 16.634 | 17.213 | 17.415 | 599 |
| 910–920.0 s | 600 | 16.643 | 17.157 | 17.440 | 600 |
| 920–930.0 s | 600 | 16.638 | 17.155 | 17.403 | 600 |
| 930–940.0 s | 600 | 16.639 | 17.190 | 17.345 | 600 |
| 940–950.0 s | 600 | 16.637 | 17.192 | 17.362 | 600 |
| 950–960.0 s | 600 | 16.629 | 17.179 | 17.374 | 600 |
| 960–970.0 s | 600 | 16.634 | 17.160 | 17.393 | 600 |
| 970–980.0 s | 599 | 16.638 | 17.226 | 17.458 | 599 |
| 980–990.0 s | 600 | 16.633 | 17.158 | 17.324 | 600 |
| 990–1000.0 s | 600 | 16.634 | 17.178 | 17.399 | 600 |
| 1000–1010.0 s | 600 | 16.633 | 17.159 | 17.356 | 600 |
| 1010–1020.0 s | 600 | 16.638 | 17.160 | 17.448 | 600 |
| 1020–1030.0 s | 600 | 16.641 | 17.156 | 17.388 | 600 |
| 1030–1040.0 s | 600 | 16.636 | 17.196 | 17.471 | 600 |
| 1040–1050.0 s | 600 | 16.634 | 17.149 | 17.308 | 600 |
| 1050–1060.0 s | 600 | 16.638 | 17.176 | 17.379 | 600 |
| 1060–1070.0 s | 600 | 16.635 | 17.152 | 17.344 | 600 |
| 1070–1080.0 s | 600 | 16.634 | 17.160 | 17.336 | 600 |
| 1080–1090.0 s | 600 | 16.626 | 17.147 | 17.294 | 600 |
| 1090–1100.0 s | 600 | 16.639 | 17.152 | 17.358 | 600 |
| 1100–1110.0 s | 600 | 16.644 | 17.141 | 17.414 | 600 |
| 1110–1120.0 s | 600 | 16.635 | 17.169 | 17.356 | 600 |
| 1120–1130.0 s | 600 | 16.635 | 17.155 | 17.338 | 600 |
| 1130–1140.0 s | 600 | 16.630 | 17.146 | 17.444 | 600 |
| 1140–1150.0 s | 600 | 16.631 | 17.161 | 17.367 | 600 |
| 1150–1160.0 s | 600 | 16.633 | 17.158 | 17.402 | 600 |
| 1160–1170.0 s | 600 | 16.633 | 17.159 | 17.385 | 600 |
| 1170–1180.0 s | 600 | 16.630 | 17.190 | 17.382 | 600 |
| 1180–1190.0 s | 600 | 16.639 | 17.170 | 17.370 | 600 |
| 1190–1200.0 s | 600 | 16.631 | 17.142 | 17.284 | 600 |

Collector frame storage: 72,120 preallocated slots, **1,226,040 exact packed payload bytes**, allocated before warmup. This does not include container/allocator overhead or accumulating monitor/probe dictionaries. Their post-run serialized content is 724,024 bytes, which is not an allocated-RAM estimate. The external Python sampler's process peak RSS is 29.6 MiB and is separate from game RSS. No instrumentation subtraction is applied.


Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:

| Scene | Load → ready ms | Load → first render-post-draw ms |
| --- | ---: | ---: |
| VS01 | 94.638 | 570.804 |
| W01S01 | 58.500 | 303.935 |
| W01S02 | 69.100 | 163.604 |
| W01S03 | 54.040 | 147.225 |

Injected input → changed render-state observation: 0/0 probes changed an on-screen target, p50 0.000 ms / p95 0.000 ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.

The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.

Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.

References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).

Run issues:

- Engine exited with code 1.
- No passing runtime profile report was produced.
