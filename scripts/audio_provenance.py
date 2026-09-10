#!/usr/bin/env python3
"""Hash-bound music provenance; technical verification is never an audio audition.

`verify-existing` checks the current WAV/Ogg pair and refreshes JSON only.
`transcode` validates a temporary Ogg before replacing output and its metadata.
`check` verifies stored source/output hashes without FFmpeg or file mutations.
`self-test` uses temporary copies, including a full deterministic regeneration.
All commands accept --audio-dir; the default is this project's assets/audio.

FFmpeg interfaces: https://ffmpeg.org/ffmpeg.html and https://ffmpeg.org/ffprobe.html
"""
from array import array
from pathlib import Path
import argparse
import contextlib
import copy
import hashlib
import io
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import wave

DEFAULT = Path(__file__).resolve().parents[1] / "assets/audio"
SOURCE = "assets/audio/music.wav"
OUTPUT = "assets/audio/music.ogg"
PADDING_LIMIT = 2048  # one Vorbis block; recorded explicitly, not a seamlessness claim


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, data):
    path = Path(path)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, prefix=".audio-", delete=False) as out:
        temp = Path(out.name)
        json.dump(data, out, indent=2)
        out.write("\n")
    try:
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def music_source(directory, manifest):
    items = [a for a in manifest["assets"] if a.get("file") == SOURCE]
    require(len(items) == 1, "Manifest must identify one editable music WAV")
    require(items[0]["sha256"] == sha(directory / "music.wav"), "Music WAV differs from its manifest")
    with wave.open(str(directory / "music.wav"), "rb") as recording:
        rate, channels, frames = recording.getframerate(), recording.getnchannels(), recording.getnframes()
        require((rate, channels, recording.getsampwidth()) == (44100, 2, 2), "Expected 44.1 kHz stereo PCM16 source")
        samples = array("h", recording.readframes(frames))
    if sys.byteorder != "little":
        samples.byteswap()
    require(frames > 0 and len(samples) == frames * channels, "Complete nonempty source PCM required")
    return {"sha256": items[0]["sha256"], "rate": rate, "channels": channels, "frames": frames}, samples


def stored_derivative(directory, manifest, report):
    """Return a previous verification only if both current files and records match.

    This deliberately drops legacy metadata lacking source/decode verification.
    Run verify-existing once to migrate an existing matching pair without encoding.
    """
    try:
        derivative = manifest["runtime_music_derivative"]
        verification = derivative["verification"]
        require(derivative["schema_version"] == 2, "Derivative schema is not verified version 2")
        require(derivative["source"] == SOURCE and derivative["path"] == OUTPUT, "Unexpected derivative paths")
        source_hash, output_hash = sha(directory / "music.wav"), sha(directory / "music.ogg")
        require(derivative["source_sha256"] == source_hash == verification["source_sha256"], "Derivative source hash is stale")
        require(derivative["sha256"] == output_hash == verification["output_sha256"], "Derivative output hash is stale")
        music_source(directory, manifest)
        require(report["runtime_music_derivative"] == verification, "Manifest/report verification disagrees")
        require(verification["status"] == "pass", "Previous verification did not pass")
        probe, signal = verification["probe"], verification["decoded_signal"]
        require((probe["codec_name"], probe["sample_rate_hz"], probe["channels"]) == ("vorbis", 44100, 2), "Unexpected verified stream")
        require(signal["signal_present"] is True and signal["non_finite_samples"] == signal["clipped_samples"] == 0, "Previous signal verification failed")
        require(signal["frames"] > 0 and len(signal["pcm_f32le_sha256"]) == 64, "Missing full decoded signal evidence")
        require(abs(signal["source_frame_difference"]) <= PADDING_LIMIT, "Decoded duration exceeds codec padding allowance")
        require(signal["source_correlation"] >= .98 and signal["source_rmse"] <= .01, "Decoded audio does not match editable source")
        return copy.deepcopy(derivative), "verified matching source/output and report"
    except (OSError, KeyError, TypeError, ValueError, wave.Error) as error:
        return None, str(error)


def preserve_derivative(directory, manifest, report):
    """Used after WAV generation, before replacing the two JSON documents."""
    try:
        old_manifest = read_json(directory / "manifest.json")
        old_report = read_json(directory / "technical_report.json")
        derivative, reason = stored_derivative(directory, old_manifest, old_report)
        if derivative:
            # The newly generated WAV record must match the verified source too.
            music_source(directory, manifest)
            manifest["runtime_music_derivative"] = derivative
            report["runtime_music_derivative"] = copy.deepcopy(derivative["verification"])
    except (OSError, KeyError, TypeError, ValueError, wave.Error) as error:
        derivative, reason = None, str(error)
    report["runtime_music_derivative_preservation"] = {
        "status": "preserved" if derivative else "omitted",
        "reason": reason,
        "note": "Matching stored technical evidence only; no playback audition or re-encoding.",
    }
    return derivative is not None


def run(command):
    return subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def verify_pair(directory, output, manifest):
    source, original = music_source(directory, manifest)
    output_hash = sha(output)
    probe = json.loads(run(["ffprobe", "-v", "error", "-select_streams", "a", "-show_entries",
        "stream=codec_name,sample_rate,channels,duration:format=format_name,duration", "-of", "json", str(output)]))
    require(len(probe["streams"]) == 1, "Expected one audio stream")
    stream = probe["streams"][0]
    require(probe["format"]["format_name"] == "ogg", "Expected Ogg container")
    require((stream["codec_name"], int(stream["sample_rate"]), stream["channels"]) == ("vorbis", source["rate"], source["channels"]), "Expected matching stereo Vorbis stream")
    duration = float(stream.get("duration", probe["format"]["duration"]))
    require(math.isfinite(duration) and abs(duration * source["rate"] - source["frames"]) <= PADDING_LIMIT, "Probed duration differs from source")
    pcm = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-xerror", "-i", str(output),
        "-map", "0:a:0", "-f", "f32le", "-c:a", "pcm_f32le", "pipe:1"])
    require(len(pcm) > 0 and len(pcm) % 8 == 0, "Complete nonempty stereo float decode required")
    decoded = array("f", pcm)
    if sys.byteorder != "little":
        decoded.byteswap()
    require(all(math.isfinite(value) for value in decoded), "Decoded non-finite samples")
    frames = len(decoded) // 2
    require(abs(frames - source["frames"]) <= PADDING_LIMIT, "Decoded frame count differs from source")
    peak = max(abs(value) for value in decoded)
    require(0 < peak < 1, "Decoded audio is silent or clipped")
    energy = sum(value * value for value in decoded)
    count = min(len(original), len(decoded))
    source_energy = sum(value * value for value in original[:count]) / 32768.0**2
    decoded_energy = sum(value * value for value in decoded[:count])
    covariance = sum(original[i] / 32768.0 * decoded[i] for i in range(count))
    require(source_energy > 0 and decoded_energy > 0, "Source or matching decoded interval is silent")
    correlation = covariance / math.sqrt(source_energy * decoded_energy)
    rmse = math.sqrt(sum((original[i] / 32768.0 - decoded[i])**2 for i in range(count)) / count)
    require(correlation >= .98 and rmse <= .01, "Ogg signal does not match its claimed editable source")
    require(sha(directory / "music.wav") == source["sha256"] and sha(output) == output_hash, "Audio files changed during verification")
    return {
        "status": "pass", "method": "ffprobe and complete FFmpeg float32 decode; source waveform comparison",
        "source_sha256": source["sha256"], "output_sha256": output_hash,
        "ffmpeg_version": run(["ffmpeg", "-version"]).decode().splitlines()[0],
        "ffprobe_version": run(["ffprobe", "-version"]).decode().splitlines()[0],
        "probe": {"codec_name": "vorbis", "container": "ogg", "sample_rate_hz": source["rate"], "channels": 2, "duration_seconds": duration},
        "decoded_signal": {"frames": frames, "signal_present": True, "non_finite_samples": 0, "clipped_samples": 0,
            "peak_dbfs": round(20 * math.log10(peak), 5), "rms_dbfs": round(10 * math.log10(energy / len(decoded)), 5),
            "pcm_f32le_sha256": hashlib.sha256(pcm).hexdigest(), "source_frame_difference": frames - source["frames"],
            "codec_padding_allowance_frames": PADDING_LIMIT, "source_correlation": round(correlation, 9), "source_rmse": round(rmse, 9),
            "boundary_step": max(abs(decoded[0] - decoded[-2]), abs(decoded[1] - decoded[-1]))},
        "audition_status": "unverified; no listening or subjective seamlessness claim",
    }


def update_derivative(directory, transcode=False):
    directory = Path(directory).resolve()
    manifest, report = read_json(directory / "manifest.json"), read_json(directory / "technical_report.json")
    music_source(directory, manifest)
    with tempfile.TemporaryDirectory(prefix=".music-", dir=directory) as work:
        output = Path(work) / "music.ogg" if transcode else directory / "music.ogg"
        if transcode:
            run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-xerror", "-y", "-i", str(directory / "music.wav"),
                 "-c:a", "vorbis", "-strict", "-2", "-q:a", "5", str(output)])
        verification = verify_pair(directory, output, manifest)
        derivative = {"schema_version": 2, "path": OUTPUT, "source": SOURCE,
            "tool": "FFmpeg native Vorbis encoder", "command": "./scripts/transcode_music.sh",
            "source_sha256": verification["source_sha256"], "sha256": verification["output_sha256"],
            "verification": verification,
            "note": "WAV remains editable; Ogg bytes and decoded signal verified. Subjective audition remains unverified."}
        manifest["runtime_music_derivative"] = derivative
        report["runtime_music_derivative"] = copy.deepcopy(verification)
        report.pop("runtime_music_derivative_preservation", None)
        if transcode:
            os.replace(output, directory / "music.ogg")
        write_json(directory / "manifest.json", manifest)
        write_json(directory / "technical_report.json", report)
    return derivative


def self_test(source_dir):
    """Full pipeline tests on copies; shipped audio and JSON remain untouched."""
    source_dir = Path(source_dir).resolve()
    original_hashes = {p.name: sha(p) for p in source_dir.iterdir() if p.suffix in (".wav", ".ogg", ".json")}
    assertions = []
    def check(ok, label):
        require(ok, label)
        assertions.append(label)
    with tempfile.TemporaryDirectory(prefix="tt-audio-provenance-") as work:
        fixture = Path(work) / "audio"
        shutil.copytree(source_dir, fixture)
        audio_hashes = {p.name: sha(p) for p in fixture.iterdir() if p.suffix in (".wav", ".ogg")}
        result = update_derivative(fixture)
        check(all(sha(fixture / name) == value for name, value in audio_hashes.items()), "verify-existing changes JSON only")
        manifest, report = read_json(fixture / "manifest.json"), read_json(fixture / "technical_report.json")
        check(stored_derivative(fixture, manifest, report)[0] == result, "matching verified derivative is retained")
        bad = copy.deepcopy(manifest); bad["runtime_music_derivative"].pop("verification")
        check(stored_derivative(fixture, bad, report)[0] is None, "unverified legacy record is rejected")
        bad = copy.deepcopy(manifest); bad["runtime_music_derivative"]["source_sha256"] = "0" * 64
        check(stored_derivative(fixture, bad, report)[0] is None, "stale source hash is rejected")
        bad_report = copy.deepcopy(report); bad_report["runtime_music_derivative"]["status"] = "fail"
        check(stored_derivative(fixture, manifest, bad_report)[0] is None, "disagreeing verification report is rejected")
        ogg = (fixture / "music.ogg").read_bytes()
        (fixture / "music.ogg").write_bytes(ogg + b"changed")
        check(stored_derivative(fixture, manifest, report)[0] is None, "changed Ogg bytes are rejected")
        (fixture / "music.ogg").unlink()
        check(stored_derivative(fixture, manifest, report)[0] is None, "missing Ogg is rejected")
        (fixture / "music.ogg").write_bytes(ogg)
        # Real generator execution, preserving its exact synthesized WAV bytes.
        import generate_audio
        old_out = generate_audio.OUT
        try:
            generate_audio.OUT = fixture
            with contextlib.redirect_stdout(io.StringIO()):
                generate_audio.generate()
        finally:
            generate_audio.OUT = old_out
        check(all(sha(fixture / name) == value for name, value in audio_hashes.items()), "full regeneration leaves all WAV/Ogg bytes identical")
        fresh_manifest, fresh_report = read_json(fixture / "manifest.json"), read_json(fixture / "technical_report.json")
        check(fresh_manifest["runtime_music_derivative"] == result, "full regeneration preserves matching derivative metadata")
        check(fresh_report["runtime_music_derivative_preservation"]["status"] == "preserved", "regeneration records preservation evidence")
        transcoded = update_derivative(fixture, transcode=True)
        check(transcoded["sha256"] == sha(fixture / "music.ogg"), "transcode automatically records actual new Ogg hash")
        check(transcoded["source_sha256"] == sha(fixture / "music.wav"), "transcode binds editable source hash")
        check(stored_derivative(fixture, read_json(fixture / "manifest.json"), read_json(fixture / "technical_report.json"))[0] == transcoded, "newly transcoded probe/decode evidence is preservable")
        before_failure = {name: sha(fixture / name) for name in ["music.ogg", "manifest.json", "technical_report.json"]}
        real_run = globals()["run"]
        def invalid_candidate(command):
            if "-q:a" in command:
                Path(command[-1]).write_bytes(b"invalid Ogg fixture")
                return b""
            return real_run(command)
        try:
            globals()["run"] = invalid_candidate
            try:
                update_derivative(fixture, transcode=True)
                raise AssertionError("invalid encoder output was accepted")
            except (ValueError, subprocess.CalledProcessError):
                check(all(sha(fixture / name) == value for name, value in before_failure.items()), "failed candidate decode preserves prior Ogg and metadata")
        finally:
            globals()["run"] = real_run
        # A mislabeled but valid WAV must not be accepted as the Ogg's source.
        wave_bytes = (fixture / "music.wav").read_bytes()
        with wave.open(str(fixture / "music.wav"), "wb") as recording:
            recording.setparams((2, 2, 44100, 0, "NONE", "not compressed"));recording.writeframes(bytes(len(wave_bytes) - 44))
        invalid_manifest = read_json(fixture / "manifest.json")
        for item in invalid_manifest["assets"]:
            if item["file"] == SOURCE: item["sha256"] = sha(fixture / "music.wav")
        try:
            verify_pair(fixture, fixture / "music.ogg", invalid_manifest)
            raise AssertionError("silent false source was accepted")
        except ValueError:
            assertions.append("decoded-source comparison rejects a false silent source")
    check(all(sha(source_dir / name) == value for name, value in original_hashes.items()), "shipped WAV/Ogg/JSON bytes are unchanged after fixture suite")
    return {"result": "PASS", "checks": len(assertions), "assertions": assertions,
        "shipped_hashes_unchanged": original_hashes, "verified_existing_signal": result["verification"],
        "fixture_transcode_hash": transcoded["sha256"], "audition_status": "unverified; no listening performed"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["verify-existing", "transcode", "check", "self-test"])
    parser.add_argument("--audio-dir", type=Path, default=DEFAULT)
    args = parser.parse_args()
    if args.command == "self-test":
        result = self_test(args.audio_dir)
    elif args.command == "check":
        result, reason = stored_derivative(args.audio_dir, read_json(args.audio_dir / "manifest.json"), read_json(args.audio_dir / "technical_report.json"))
        require(result is not None, reason)
    else:
        result = update_derivative(args.audio_dir, transcode=args.command == "transcode")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
