#!/usr/bin/env python3
"""Rebuild Tiny Trouble's original, editable breakfast audio with Python only.

Run from any directory: python3 scripts/generate_audio.py
No samples, copyrighted melodies, network calls or external dependencies are used.
All pitches, envelopes, rhythms and mixes are authored below. Files are stereo
44.1 kHz PCM16. Sound effects peak at -12 dBFS; music peaks at -18 dBFS.
The music is a 20-second cyclic arrangement: tails and room echoes wrap into the
beginning, so playback should loop without inserting an artificial fade or gap.
Technical inspection is not listening; metadata never claims an audio audition.
"""

from array import array
from pathlib import Path
import hashlib
import json
import math
import random
import struct
import wave
from audio_provenance import preserve_derivative, write_json


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RATE = 44100
TAU = math.tau


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def blank(seconds):
    return [array("d", [0.0]) * round(seconds * RATE) for _ in range(2)]


def add_voice(track, start, midi, duration, gain=0.2, pan=0.0,
              voice="wood", bend=0.0, loop=False):
    """Rounded struck resonators; no square waves or hard sample boundaries."""
    count = len(track[0])
    begin = round(start * RATE)
    n = round(duration * RATE)
    pitch = hz(midi)
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    if voice == "chime":
        partials = ((1, 1, 1), (2.01, .18, .55), (3.99, .055, .25))
        decay = 3.8
    elif voice == "pad":
        partials = ((1, 1, 1), (2, .085, 1), (3, .018, 1))
        decay = 0.2
    else:
        partials = ((1, 1, 1), (2.756, .20, .23), (5.404, .026, .09))
        decay = 5.1
    for i in range(n):
        j = begin + i
        if j >= count and not loop:
            break
        t = i / RATE
        u = i / max(1, n - 1)
        attack = 1.0 - math.exp(-t / (.12 if voice == "pad" else .005))
        release = min(1.0, (1.0 - u) / (.20 if voice == "pad" else .08)) ** 2
        phase = TAU * pitch * (t + bend * t * t / (2.0 * duration))
        signal = 0.0
        for ratio, amplitude, sustain in partials:
            signal += math.sin(phase * ratio) * amplitude * math.exp(-decay * u / sustain)
        signal *= attack * release * gain
        track[0][j % count] += signal * left
        track[1][j % count] += signal * right


def add_felt(track, start, duration=.15, gain=.05, seed=1):
    """Quiet band-limited tap/fabric noise for a less electronic attack."""
    rng = random.Random(seed)
    begin = round(start * RATE)
    n = round(duration * RATE)
    filtered = 0.0
    for i in range(n):
        j = begin + i
        if j >= len(track[0]):
            break
        filtered += .065 * (rng.uniform(-1, 1) - filtered)
        envelope = (1 - math.exp(-i / (RATE * .004))) * math.exp(-i / (n * .15))
        envelope *= min(1.0, (n - 1 - i) / max(1, RATE * .01))
        sound = filtered * envelope * gain
        track[0][j] += sound
        track[1][j] += sound


def room(track, loop=False):
    """Short, quiet stereo reflections, using an unmodified dry source."""
    dry = [array("d", channel) for channel in track]
    count = len(track[0])
    for delay, gain in ((.061, .14), (.107, .075), (.173, .035)):
        offset = round(delay * RATE)
        for channel in (0, 1):
            for i, sample in enumerate(dry[1 - channel]):
                dest = i + offset
                if dest < count or loop:
                    track[channel][dest % count] += sample * gain


def save(name, track, peak_db=-12.0, loop=False, description=""):
    room(track, loop)
    # Remove any numerical DC before gain staging. No hard clip/limiter required.
    for channel in track:
        dc = sum(channel) / len(channel)
        for i in range(len(channel)):
            channel[i] -= dc
    peak = max(max(abs(x) for x in channel) for channel in track)
    factor = 10 ** (peak_db / 20.0) / max(peak, 1e-12)
    pcm = array("h")
    energy = 0.0
    for i in range(len(track[0])):
        for channel in track:
            value = channel[i] * factor
            energy += value * value
            pcm.append(round(max(-1.0, min(1.0, value)) * 32767))
    if struct.pack("=h", 1) != struct.pack("<h", 1):
        pcm.byteswap()
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as out:
        out.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(pcm.tobytes())
    rms = math.sqrt(energy / (len(track[0]) * 2))
    edge_delta = max(abs(c[0] - c[-1]) * factor for c in track)
    return {
        "id": f"AUDIO_{name.upper()}", "file": f"assets/audio/{name}.wav",
        "description": description, "seconds": len(track[0]) / RATE,
        "sample_rate_hz": RATE, "channels": 2, "sample_format": "PCM signed 16-bit",
        "peak_dbfs": peak_db, "rms_dbfs": round(20 * math.log10(max(rms, 1e-12)), 2),
        "loop": loop, "loop_boundary_delta": round(edge_delta, 7) if loop else None,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "source": "scripts/generate_audio.py", "provenance": "Original deterministic additive synthesis; no external audio samples.",
        "technical_status": "Generated, WAV encoding and peak limits checked by generator.",
        "audition_status": "unverified; generated audio has not been listened to by this script",
    }


def phrase(name, notes, duration, description, voice="wood", peak_db=-12):
    track = blank(duration)
    for index, (when, pitch, length, gain) in enumerate(notes):
        add_voice(track, when, pitch, length, gain, (-.12, .10, 0)[index % 3], voice)
    return save(name, track, peak_db=peak_db, description=description)


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    manifest.append(phrase("resize_up", [(0, 65, .48, .30), (.11, 69, .46, .25), (.23, 72, .62, .22)],
                          1.10, "Warm rising three-note tool chime.", "chime"))
    manifest.append(phrase("resize_down", [(0, 72, .44, .25), (.10, 69, .44, .25), (.22, 65, .62, .28)],
                          1.10, "Matching descending tool chime.", "chime"))
    manifest.append(phrase("pickup", [(0, 69, .27, .24), (.055, 72, .30, .13)],
                          .58, "Small rounded wooden lift.", peak_db=-15))
    track = blank(.56)
    add_voice(track, 0, 53, .30, .27)
    add_voice(track, .025, 65, .22, .05)
    add_felt(track, 0, gain=.16)
    manifest.append(save("place", track, -14, description="Low wooden socket contact with a soft felt transient."))
    manifest.append(phrase("reject", [(0, 62, .22, .17), (.13, 60, .29, .15)],
                          .66, "Gentle two-note refusal; never an alarm or buzzer.", peak_db=-17))
    manifest.append(phrase("checkpoint", [(0, 65, .55, .22), (.18, 72, .70, .18), (.32, 77, .75, .13)],
                          1.38, "Soft saved-progress confirmation.", "chime", -15))
    track = blank(.60)
    add_voice(track, 0, 55, .34, .22, bend=.4)
    add_felt(track, 0, gain=.07)
    manifest.append(save("jump", track, -17, description="Rounded rising wooden spring."))
    track = blank(.66)
    add_voice(track, 0, 45, .38, .24, bend=-.10)
    add_voice(track, .03, 57, .18, .035)
    add_felt(track, 0, .22, .25, seed=2)
    manifest.append(save("land", track, -15, description="Soft padded contact and low resonant thump."))
    track = blank(1.70)
    add_voice(track, 0, 41, .80, .25, bend=1.1)
    add_voice(track, .08, 53, .75, .09, bend=.6)
    for when, pitch in ((.24, 65), (.37, 69), (.51, 72), (.65, 77)):
        add_voice(track, when, pitch, .69, .10, voice="chime")
    add_felt(track, 0, .20, .08, seed=3)
    manifest.append(save("launch", track, -12, description="Toy spring release into the ascending breakfast motif."))
    manifest.append(phrase("complete", [(0, 65, .7, .25), (.24, 69, .7, .22), (.48, 72, .9, .22),
                                             (.84, 77, 1.2, .20), (.84, 60, 1.25, .13), (1.12, 81, 1.2, .10)],
                          2.62, "Gentle four-note breakfast celebration with a warm final chord.", "chime", -13))
    manifest.append(phrase("discovery", [(0, 72, .55, .18), (.16, 77, .55, .19), (.36, 81, .9, .13), (.58, 79, 1.0, .11)],
                          1.92, "Curious picnic-panel discovery chimes.", "chime", -15))

    # Eight 3/4 bars at 72 quarter notes per minute, in F major / D minor.
    # The restrained four-note motif is available for later instrumentation.
    track = blank(20)
    beat = 5.0 / 6.0
    chords = ((41, 57, 60, 65), (45, 57, 60, 64), (38, 57, 60, 65), (46, 58, 62, 65))
    for block, chord in enumerate(chords):
        at = block * 5.0
        add_voice(track, at, chord[0], 5.5, .046, voice="pad", loop=True)
        for i, pitch in enumerate(chord[1:]):
            add_voice(track, at + .07 * i, pitch, 5.7, .014, pan=(i - 1) * .25, voice="pad", loop=True)
        for step, index in ((0, 1), (1.5, 2), (3, 3), (4.5, 2)):
            add_voice(track, at + step * beat, chord[index], 2.4, .058,
                      pan=.18 if index % 2 else -.18, loop=True)
    melody = ((0, 77), (1.5, 81), (3, 84), (5, 81), (6, 79), (8, 76),
              (10, 77), (12, 81), (13.5, 84), (15, 86), (17, 84), (19.5, 81), (21, 79), (22.5, 77))
    for i, (step, pitch) in enumerate(melody):
        add_voice(track, step * beat, pitch, 1.9, .053 if i % 3 else .065,
                  pan=(-.12 if i % 2 else .12), voice="wood", loop=True)
    manifest.append(save("music", track, -18, loop=True,
                         description="20-second original breakfast loop: felt mallets, warm plucks, and quiet sustained resin-toy chords."))
    info = {"schema_version": 1, "generator": "python3 scripts/generate_audio.py",
            "license_note": "Original project assets, generated from project-owned source; no external samples or melody quotations.",
            "audition_status": "Unverified until supported playback is actually reviewed.",
            "assets": manifest}
    checks = []
    for item in manifest:
        with wave.open(str(OUT / Path(item["file"]).name), "rb") as recording:
            assert recording.getnchannels() == 2
            assert recording.getsampwidth() == 2
            assert recording.getframerate() == RATE
            samples = array("h", recording.readframes(recording.getnframes()))
            if struct.pack("=h", 1) != struct.pack("<h", 1):
                samples.byteswap()
            peak = max(abs(value) for value in samples)
            assert 0 < peak <= 8231
            check = {"asset": item["file"], "pcm_parse": "pass", "signal_present": True,
                     "peak_sample": peak, "clipped_samples": 0}
            if item["loop"]:
                check["boundary_step_sample_units"] = max(abs(samples[0] - samples[-2]), abs(samples[1] - samples[-1]))
                check["largest_internal_step_sample_units"] = max(abs(samples[i] - samples[i - 2]) for i in range(2, len(samples)))
            checks.append(check)
    report = {"status": "technical checks passed", "method": "wave decode and sample inspection after generation",
              "limitations": ["Playback and perceived mix quality have not been auditioned.",
                              "In-game concurrency, settings and playback remain integration checks."],
              "checks": checks}
    preserve_derivative(OUT, info, report)
    write_json(OUT / "manifest.json", info)
    write_json(OUT / "technical_report.json", report)
    print(json.dumps({"written": len(manifest), "output": str(OUT),
                      "music_seconds": 20, "audition_status": "unverified"}, indent=2))


if __name__ == "__main__":
    generate()
