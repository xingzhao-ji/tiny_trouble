# TT-027 native profiling foundation

The [60-second baseline](macos_stable_022_1080p_60s/README.md) measures the preserved **0.2.2 macOS app**, using an external fixture harness. It does not measure the adaptive UI changes subsequently made in source.

On this Apple M4 Pro / 48 GiB Mac, the focused 1920×1080 run retained VSync, the 60 FPS cap, normal audio, and game save I/O. It sampled 3,599 frames and four completed toast flights: frame intervals p50 16.644 ms / p95 17.144 ms / p99 18.700 ms; active RSS peak 236.3 MiB; active CPU interval p50 36.4% of one logical CPU. Captures were disabled. Other applications remained open; coordination prevented concurrent agent engine/heavy tasks, not all OS background activity.

Scene loads/readiness and first-render timing were measured separately. Raw frame CSV, process samples, conditions, executable/PCK hashes, engine logs, and the exact measured harness are retained. This short single-host run does not establish other-platform performance, long-session leak freedom, battery life, thermal sustainability, or physical controller/touch behavior.

The original baseline observed 45 input responses; five jump probes were superseded by the following movement probe. [The measurement review](macos_stable_022_1080p_60s/measurement_review.json) documents their censored timing without changing the raw result. The collector now retains simultaneous probes and reports render-post-draw counts and explicit observation status. A [separate four-second native smoke](latency_collector_smoke_02/README.md) confirmed all four probes, including overlapping movement/jump, with clean shutdown. That smoke was unfocused and is **harness validation only**, not a replacement performance measurement.

Reproduce a new native run with a fresh output directory:

```sh
python3 scripts/profile_macos.py --output evidence/platform_profile/new_run
```

The sampler refuses to overwrite an existing report. It records app/PCK hashes and archives its harness source. `--smoke --headless --duration 3` is available for parser/lifecycle validation; headless results are explicitly excluded from native performance claims. Coordinate exclusive engine/CPU-heavy use before measured runs. No runtime resource tuning was made for this baseline.

The current collector additionally accepts `--warmup 2..120` and `--duration 2..1200`. Warmup exercises the same walking, resizing and flight fixture; measurement starts without resetting its current motion. Warmup timestamps, workload counters and RSS samples are separate from the active statistics. For a future fresh candidate run, after package gates and an exclusive native slot:

```sh
python3 scripts/profile_macos.py --warmup 120 --duration 1200 \
  --output evidence/platform_profile/new_candidate_1080p_20min
```

At the 60 FPS cap, that run preallocates 72,120 frame slots: **1,226,040 bytes of packed sample payload** before warmup. Container headers, backing-capacity rounding and allocator overhead are not included in that number. Monitor/event/probe dictionaries still accumulate; their counts and serialized content sizes are reported without equating serialization size to allocated RAM. A hard 360,000-slot bound fails explicitly on overflow. External sampler peak RSS is recorded separately from the game. CPU/GPU temperatures, component power and fan sensors remain unknown; `pmset` thermal notifications do not establish their values or absence of throttling.

Two new **headless harness checks**, not performance baselines, validate the phase/storage change: [2-second warmup / 3-second measurement](warmup_collector_headless_smoke_03/README.md), and [15-second warmup / 4-second measurement](warmup_flight_headless_smoke_04/README.md). The latter performed 592 walking frames, 187 flight frames and one complete flight during warmup, then retained 241 separate measured frames. Both exited cleanly. Additional checks verified nonnegative active-only frame/probe/event timestamps, phase boundaries, CSV/count/payload consistency, invalid CLI range rejection and the archived original baseline harness hash. The original 60-second files remain unchanged.

A final [native collector smoke](warmup_collector_native_smoke_05/README.md) passed with 2.02 seconds of active warmup, 3 seconds of measurement and 181 frame records. All measured frames were unfocused and the brief interval contained no new input probe starts, so this check verifies native frame collection and clean shutdown only; its short timings are **not a sustained performance result**. The later candidate 0.2.3 sustained attempt is documented below; it did not pass workload validation.


The preserved [0.2.3 sustained attempt](macos_candidate_023_1080p_20m/post_run_review/REVIEW.md) ran for 120 seconds of warmup plus 1,200 measured seconds but **failed**: all 71,963 measured frames retained `flying=true`, with no complete flights, walking or new input probes. Focus-loss pause is a plausible cause, not an established fact from that older collector: it did not record pause state or transforms. Those raw files and their original harness remain unchanged. The run cannot establish sustained active-gameplay performance.

The schema 3 collector now requires 0.5 seconds of continuous native foreground readiness within a 10-second startup window. It then calls the normal production Start/Resume commands once. During warmup and measurement it aborts immediately on native focus loss, after 0.5 seconds paused, 0.75 seconds of stationary flight, a flight exceeding five seconds, or 1.5 seconds of stationary intended walking. It does not disable lifecycle notifications or automatically resume an interrupted run. Warmups of at least 20 seconds must include a completed flight before measurement starts. Actual position changes qualify the walking/flight workload counters; stale flags alone do not. Per-second diagnostics preserve phase, pause, focus, position, flight clock, current fixture action and held movement strengths. The CSV adds paused and position-change flags within the same bounded 17-byte frame payload.

Three short checks against the frozen 0.2.3 executable validate the repair:

- [Warmup pause injection](watchdog_warmup_pause_06/README.md): expected **FAIL**, `production_paused` after 1.53 seconds of warmup; zero active frame/RSS samples and clean exit 1.
- [Frozen flight injection](watchdog_stalled_flight_07/README.md): expected **FAIL**, `stationary_flight` after 0.767 seconds without a position change, despite `flying=true` and `paused=false`; clean exit 1. This directly checks the stale-flag failure class.
- [Native focused smoke](watchdog_native_08/README.md): **PASS**, startup ready in 0.799 seconds; 2.02 seconds of actual walking warmup plus 18 seconds of measurement, all 1,081 measured frames focused, 764 walking-motion frames, 186 flight-motion frames, one completed flight and clean exit 0. All four separate scene load probes ran. This is harness validation, not a replacement sustained performance result.

Fault injection is available only with `--smoke --fault warmup_pause|active_pause|stalled_flight`. A correctly detected deliberate fault keeps its nonzero exit and FAIL report; it is never relabeled as a passing performance run. The external sampler and runtime both use schema 3, and a failure before active startup cannot accidentally classify startup/warmup RSS as active sampling. The sampler refuses to overwrite any existing engine log or report. Source copies and original conditions remain beside each run. A new long-run result is still required before any sustained-performance acceptance.
