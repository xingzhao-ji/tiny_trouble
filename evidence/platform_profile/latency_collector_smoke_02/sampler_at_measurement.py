#!/usr/bin/env python3
"""Run the stable native app's external fixture harness; sample only its PID.

No third-party packages, privilege escalation, captures, or runtime modifications.
RSS is macOS ps resident size (KiB), not private footprint or engine allocation.
CPU intervals derive from cumulative process CPU time / elapsed wall time.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_EXE = ROOT / "builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express"


def read_command(args: list[str]) -> str:
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else "unavailable"


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def cpu_seconds(value: str) -> float:
    parts = value.split(":")
    total = 0.0
    for part in parts:
        total = total * 60 + float(part)
    return total


def summarize(values: list[float]) -> dict:
    if not values:
        return {"samples": 0, "p50": None, "p95": None, "p99": None, "max": None}
    values = sorted(values)
    return {"samples": len(values), **{f"p{p}": values[min(len(values) - 1, int(len(values) * p / 100))] for p in (50, 95, 99)}, "max": values[-1]}


def sample_process(pid: int, start: float, previous: dict | None) -> dict | None:
    sampled = time.monotonic()
    output = read_command(["/bin/ps", "-p", str(pid), "-o", "rss=,time=,%cpu="])
    try:
        rss, cpu, reported = output.split()
        result = {"process_wall_seconds": sampled - start, "sample_monotonic_seconds": sampled,
                  "unix_time_seconds": time.time(),
                  "rss_bytes": int(rss) * 1024, "cumulative_cpu_seconds": cpu_seconds(cpu),
                  "ps_reported_cpu_percent": float(reported), "interval_cpu_percent": None}
    except (ValueError, TypeError):
        return None
    if previous:
        result["interval_cpu_percent"] = max(0.0, 100 * (result["cumulative_cpu_seconds"] - previous["cumulative_cpu_seconds"]) / (sampled - previous["sample_monotonic_seconds"]))
    return result


def metadata(executable: Path) -> dict:
    info = executable.parent.parent / "Info.plist"
    version = {}
    if info.exists():
        with info.open("rb") as stream:
            data = plistlib.load(stream)
        version = {key: data.get(key) for key in ("CFBundleIdentifier", "CFBundleShortVersionString", "CFBundleVersion")}
    packs = list((executable.parent.parent / "Resources").glob("*.pck"))
    power = read_command(["/usr/bin/pmset", "-g", "batt"])
    power_source = "AC Power" if "AC Power" in power else "Battery Power" if "Battery Power" in power else "unavailable"
    return {"recorded_utc": datetime.now(timezone.utc).isoformat(), "platform": platform.platform(),
            "machine_architecture": platform.machine(), "hardware_model": read_command(["/usr/sbin/sysctl", "-n", "hw.model"]),
            "cpu": read_command(["/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string"]),
            "physical_memory_bytes": read_command(["/usr/sbin/sysctl", "-n", "hw.memsize"]),
            "power_source": power_source, "thermal_status_before": read_command(["/usr/bin/pmset", "-g", "therm"]),
            "executable": str(executable), "executable_sha256": digest(executable), "bundle": version,
            "packs": [{"file": str(path), "bytes": path.stat().st_size, "sha256": digest(path)} for path in packs],
            "harness_sha256": digest(ROOT / "tests/platform/profile_runtime.gd")}


def markdown(report: dict) -> str:
    runtime = report.get("runtime") or {}
    pacing = runtime.get("process_frame_ms", {})
    process = report["external_process"]
    condition = runtime.get("conditions", {}).get("start", {})
    host = report["host"]
    smoke = runtime.get("measurement_kind") == "harness_smoke_not_a_performance_result"
    heading = "# Harness smoke — not a performance baseline" if smoke else "# Native macOS runtime baseline"
    lines = [heading, "", f"Result: **{report['result']}**. {runtime.get('active_wall_seconds', 0):.2f} seconds of continuous active VS01 fixture sampling on {host['cpu']} / {host['hardware_model']}. " + ("Harness validation only; these timings do not establish native performance." if smoke else "This is a measurement of this host only."), "",
             f"Stable app version {host['bundle'].get('CFBundleShortVersionString', 'unknown')}; native {condition.get('window_pixels')} window, logical viewport {condition.get('logical_viewport')}, cap {condition.get('runtime_max_fps')}, VSync mode {condition.get('vsync_mode')}, reported refresh {condition.get('display_refresh_hz')} Hz. Captures disabled; normal audio and game save I/O enabled. Power source: {host['power_source']}.", "",
             f"Process-frame wall intervals: p50 **{pacing.get('p50', 0):.3f} ms**, p95 **{pacing.get('p95', 0):.3f} ms**, p99 **{pacing.get('p99', 0):.3f} ms**, maximum **{pacing.get('max', 0):.3f} ms**. These include cap/VSync waits and fixture reset work. Peak reported draws: {runtime.get('peak_draw_calls')}; rendered objects: {runtime.get('peak_render_objects')}.", "",
             f"Active-period external RSS peak: **{(process.get('active_rss_bytes', {}).get('max') or 0) / 1048576:.1f} MiB**. Active process CPU interval p50/p95: {(process.get('active_interval_cpu_percent', {}).get('p50') or 0):.1f}% / {(process.get('active_interval_cpu_percent', {}).get('p95') or 0):.1f}% (100% means one fully occupied logical CPU). Whole-process RSS peak, including separate loads: {(process['rss_bytes'].get('max') or 0) / 1048576:.1f} MiB. The raw samples retain timestamps for every phase.", "",
             "| Active interval | Frames | p50 ms | p95 ms | p99 ms | Focused frames |", "| --- | ---: | ---: | ---: | ---: | ---: |"]
    for bucket in runtime.get("ten_second_buckets", []):
        stat = bucket["all_process_frame_ms"]
        lines.append(f"| {bucket['start_seconds']}–{bucket['end_seconds']} s | {stat['samples']} | {stat['p50']:.3f} | {stat['p95']:.3f} | {stat['p99']:.3f} | {bucket['focused_frame_ms']['samples']} |")
    lines += ["", "Scene loads were excluded from those frame statistics. These are in-process load/readiness measurements with OS/shared-resource caches potentially warm:", "", "| Scene | Load → ready ms | Load → first render-post-draw ms |", "| --- | ---: | ---: |"]
    for scene in runtime.get("scene_loads", []):
        lines.append(f"| {scene['scene']} | {scene['load_to_ready_ms']:.3f} | {scene['load_to_first_render_post_draw_ms']:.3f} |")
    latency = runtime.get("input_response_samples", [])
    valid = [sample for sample in latency if sample["changed_render_state_observed"] and sample["target_in_viewport"]]
    stat = summarize([sample["elapsed_ms"] for sample in valid])
    lines += ["", f"Injected input → changed render-state observation: {len(valid)}/{len(latency)} probes changed an on-screen target, p50 {(stat['p50'] or 0):.3f} ms / p95 {(stat['p95'] or 0):.3f} ms. This ends at Godot's render-post-draw signal, uses no pixel readback, and **is not physical input-to-photon latency**. Events are scheduled near process callbacks, so event phase is not randomized.", "",
              "The workload deliberately seeds a prepared route and resets its fixture between trips. Movement, size transitions, particles, boarding, flight, audio and saves run in the shipped scene. This is neither an ordinary-player route nor evidence for other devices. CPU/GPU temperature, power draw, battery life, physical controller and touch behavior remain unmeasured.", "",
              "Release static allocator counters may be unavailable; engine render memory estimates and process RSS describe different things. Instrumentation adds some CPU/memory overhead. Raw frame CSV, external process samples, engine log, executable/PCK hashes, all conditions and limitations are retained beside this summary.", "",
              "References: [Godot performance monitors](https://docs.godotengine.org/en/4.5/classes/class_performance.html), [render-post-draw signal](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw), [system memory API](https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info).", ""]
    if report["issues"]:
        lines += ["Run issues:", ""] + ["- " + issue for issue in report["issues"]] + [""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", type=Path, default=DEFAULT_EXE)
    parser.add_argument("--output", type=Path, default=ROOT / "evidence/platform_profile/macos_stable_022_1080p_60s")
    parser.add_argument("--duration", type=float, default=60)
    parser.add_argument("--width", type=int, default=1920)
    parser.add_argument("--height", type=int, default=1080)
    parser.add_argument("--smoke", action="store_true", help="Label the run as harness validation, not a performance result.")
    parser.add_argument("--headless", action="store_true", help="Only accepted with --smoke.")
    args = parser.parse_args()
    if sys.platform != "darwin": parser.error("This external sampler supports macOS only; the GDScript harness is separate.")
    if args.headless and not args.smoke: parser.error("--headless requires --smoke")
    if not 2 <= args.duration <= 300: parser.error("duration must be 2–300 seconds")
    executable = args.executable.resolve()
    if not executable.is_file(): parser.error("exported executable not found: " + str(executable))
    folder = args.output.resolve()
    folder.mkdir(parents=True, exist_ok=True)
    if (folder / "profile_report.json").exists(): parser.error("Choose a new output directory; existing measurements are retained.")
    host = metadata(executable)
    (folder / "harness_at_measurement.gd").write_bytes((ROOT / "tests/platform/profile_runtime.gd").read_bytes())
    (folder / "sampler_at_measurement.py").write_bytes(Path(__file__).read_bytes())
    command = [str(executable), "--path", str(ROOT), "--resolution", f"{args.width}x{args.height}", "--script", str(ROOT / "tests/platform/profile_runtime.gd")]
    if args.headless: command.append("--headless")
    command += ["--", f"--profile-output={folder}", f"--profile-duration={args.duration}"]
    if args.smoke: command.append("--profile-smoke")
    environment = os.environ.copy()
    environment["LC_ALL"] = "C"
    start = time.monotonic()
    samples: list[dict] = []
    print("Starting actual exported runtime; evidence:", folder, flush=True)
    with (folder / "engine.log").open("w") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, env=environment)
        deadline = start + args.duration + 45
        while process.poll() is None and time.monotonic() < deadline:
            sample = sample_process(process.pid, start, samples[-1] if samples else None)
            if sample: samples.append(sample)
            elapsed = time.monotonic() - start
            if int(elapsed) % 10 == 0:
                print(f"Profiling process {process.pid}: {elapsed:.0f} s elapsed", flush=True)
            time.sleep(1)
        timed_out = process.poll() is None
        if timed_out:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
        code = process.wait()
    wall_seconds = time.monotonic() - start
    text = (folder / "engine.log").read_text()
    issues = []
    if timed_out: issues.append("Engine exceeded the bounded run deadline and was terminated.")
    if code != 0: issues.append(f"Engine exited with code {code}.")
    for phrase in ("SCRIPT ERROR:", "ERROR:", "leaked at exit", "resources still in use"):
        if phrase in text: issues.append("Engine log contains " + phrase)
    runtime_path = folder / "runtime_profile.json"
    runtime = json.loads(runtime_path.read_text()) if runtime_path.exists() else None
    if runtime is None or runtime.get("result") != "PASS": issues.append("No passing runtime profile report was produced.")
    if runtime and not args.smoke and runtime.get("active_wall_seconds", 0) < args.duration - 0.1:
        issues.append("Requested continuous active sampling duration was not reached.")
    active_samples = [sample for sample in samples if runtime and runtime.get("active_start_unix_seconds", float("inf")) <= sample["unix_time_seconds"] <= runtime.get("active_end_unix_seconds", -float("inf"))]
    # Include a CPU interval only when both endpoints are within the active period.
    active_cpu = [sample["interval_cpu_percent"] for index, sample in enumerate(active_samples) if index > 0 and sample["interval_cpu_percent"] is not None]
    process_summary = {"sample_interval_target_seconds": 1, "sample_count": len(samples),
                       "rss_bytes": summarize([sample["rss_bytes"] for sample in samples]),
                       "interval_cpu_percent": summarize([sample["interval_cpu_percent"] for sample in samples if sample["interval_cpu_percent"] is not None]),
                       "active_sample_count": len(active_samples), "active_rss_bytes": summarize([sample["rss_bytes"] for sample in active_samples]),
                       "active_interval_cpu_percent": summarize(active_cpu),
                       "notes": ["RSS is sampled macOS ps resident size in KiB converted to bytes; not peak private footprint or a leak proof.", "Interval CPU percent derives from cumulative ps CPU time divided by monotonic wall time; 100% is one logical CPU. ps-reported %CPU is retained separately and is not the interval measure.", "Sampling spans startup, active gameplay, separate scene loads and shutdown. Use timestamps and engine stage timing to distinguish those phases."]}
    report = {"schema_version": 1, "result": "PASS" if not issues else "FAIL", "issues": issues,
              "host": host, "command": command, "engine_exit_code": code, "process_wall_seconds": wall_seconds,
              "external_process": process_summary, "thermal_status_after": read_command(["/usr/bin/pmset", "-g", "therm"]), "runtime": runtime}
    (folder / "process_samples.json").write_text(json.dumps(samples, indent=2) + "\n")
    (folder / "profile_report.json").write_text(json.dumps(report, indent=2) + "\n")
    (folder / "README.md").write_text(markdown(report))
    print(text, end="")
    print(f"External sampler: {report['result']}; exit {code}; {len(samples)} process samples; peak RSS {(process_summary['rss_bytes']['max'] or 0) / 1048576:.1f} MiB", flush=True)
    return 0 if not issues else 1


if __name__ == "__main__":
    raise SystemExit(main())
