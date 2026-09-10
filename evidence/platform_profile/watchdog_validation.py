#!/usr/bin/env python3
"""Recheck retained schema3 collector diagnostics; never launches an engine."""
import csv
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
checks = []
def check(condition, label):
    if not condition:
        raise AssertionError(label)
    checks.append(label)

def read(name):
    folder = BASE / name
    report = json.loads((folder / "profile_report.json").read_text())
    runtime = report["runtime"]
    rows = list(csv.DictReader((folder / "process_frames.csv").open()))
    check(report["schema_version"] == runtime["schema_version"] == 3, name + ": coherent schema3")
    check(report["host"]["harness_sha256"] == hashlib.sha256((folder / "harness_at_measurement.gd").read_bytes()).hexdigest(), name + ": archived measured harness hash")
    check(len(rows) == runtime["collector_memory"]["retained_frames"], name + ": retained frame count matches CSV")
    check(runtime["collector_memory"]["exact_packed_payload_bytes"] == runtime["collector_memory"]["frame_capacity"] * 17, name + ": bounded packed storage accounting")
    check(not any(marker in (folder / "engine.log").read_text() for marker in ("SCRIPT ERROR:", "ERROR:", "leaked at exit", "resources still in use")), name + ": clean complete engine log")
    check(report["harness_smoke"], name + ": explicitly a harness smoke")
    return report, runtime, rows

report, runtime, rows = read("watchdog_warmup_pause_06")
check(report["result"] == "FAIL" and report["engine_exit_code"] == 1, "Pause injection retains expected nonzero FAIL")
check(runtime["watchdog"]["failure"]["reason"] == "production_paused", "Pause reaches production pause watchdog")
check(runtime["watchdog"]["failure"]["paused"] and runtime["warmup"]["wall_seconds"] < 2, "Pause aborts before the requested warmup ends")
check(not runtime["active_started"] and not rows and report["external_process"]["active_sample_count"] == 0 and not report["external_process"]["active_ten_second_buckets"], "No active frame, RSS or bucket claims before active startup")
check(runtime["warmup"]["walking_motion_frames"] > 10, "Warmup was actually moving before deliberate pause")

report, runtime, rows = read("watchdog_stalled_flight_07")
failure = runtime["watchdog"]["failure"]
check(report["result"] == "FAIL" and report["engine_exit_code"] == 1, "Stalled flight retains expected nonzero FAIL")
check(failure["reason"] == "stationary_flight" and failure["flying"] and not failure["paused"], "Stale flying flag is detected independently of pause")
check(0.75 <= failure["seconds_without_position_change"] < 1 and not failure["flight_clock_advanced_this_frame"], "Stationary pose/clock triggers bounded flight abort")
check(runtime["workload"]["flight_motion_frames"] == 0 and runtime["workload"]["flight_frames"] > 0, "Stale flight frames do not qualify as actual motion")
check(runtime["active_wall_seconds"] < 10 and report["external_process"]["active_sample_count"] > 0, "Active stall stops early and retains appropriately scoped samples")

report, runtime, rows = read("watchdog_native_08")
check(report["result"] == "PASS" and report["engine_exit_code"] == 0, "Native healthy smoke passes and shuts down")
check(runtime["startup"]["ready"] and runtime["startup"]["native_focus_required"] and runtime["startup"]["display"]["focused"] and runtime["startup"]["production_start_and_resume_called"], "Native readiness uses focused startup plus production Start/Resume")
check(len(rows) > 1000 and all(row["window_focused"] == "true" and row["paused"] == "false" for row in rows), "Every retained native frame is focused and unpaused")
check(runtime["workload"]["completed_flights"] >= 1 and runtime["workload"]["walking_motion_frames"] > 300 and runtime["workload"]["flight_motion_frames"] > 100, "Native fixture demonstrates actual walking and completed flight")
check(len(runtime["scene_loads"]) == 4 and not runtime["watchdog"]["failure"], "Separate scene loads complete without watchdog failures")
check(all(not item["paused"] and item["focused"] for item in runtime["watchdog"]["samples"]), "Per-second diagnostics agree with healthy native activity")
check(runtime["collector_memory"]["watchdog_records"] >= 20 and len(runtime["input_response_samples"]) > 0, "Progress and response diagnostics are present")
check(hashlib.sha256((BASE / "macos_stable_022_1080p_60s/harness_at_measurement.gd").read_bytes()).hexdigest() == "bb89316619886d7994ec0993c74dd7502b011a1bb8ae068835b35e3ddcc3acf5", "Original 60-second baseline harness is unchanged")
print(json.dumps({"result": "PASS", "checks": len(checks), "scope": "Retained bounded collector validation, not a sustained performance result", "verified": checks}, indent=2))
