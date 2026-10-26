"""Tempo of what the default sink plays, as JSON lines for the bar: {"bpm": 123.4, "beat": epoch seconds of a beat}.

Only the default sink's monitor is ever recorded, so this never touches a microphone.
No player publishes the tempo, so it is measured with aubiotrack over a sliding window.
"""

import json
import os
import statistics
import subprocess
import tempfile
import threading
import time
import wave
from collections import deque
from pathlib import Path

IDLE = 2.0
CHUNK = 4.0
WINDOW = 4
HISTORY = 30
MIN_READINGS = 3
TOLERANCE = 3.0
BPM_MIN, BPM_MAX = 90.0, 180.0

state = {"status": "", "track": "", "bpm": None, "beat": None}
lock = threading.Lock()
# runtime dir is cleaned at logout unlike /tmp
tmp = Path(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir()))


def run(*args, timeout=2):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def default_sink():
    for line in run("wpctl", "inspect", "@DEFAULT_AUDIO_SINK@").splitlines():
        if "node.name" in line:
            return line.split("=", 1)[1].strip().strip('"')
    return None


def fold(bpm):
    while bpm < BPM_MIN:
        bpm *= 2
    while bpm > BPM_MAX:
        bpm /= 2
    return bpm


def settle(readings, shown):
    """The tempo to show: the densest cluster of readings, kept until another clearly beats it."""
    def support(bpm):
        return sum(abs(r - bpm) <= TOLERANCE for r in readings)

    best = max(readings, key=support)
    if shown and support(shown) >= support(best) - 1:
        return shown
    return statistics.median(r for r in readings if abs(r - best) <= TOLERANCE)


def record(seconds, sink):
    """One chunk of the sink's audio as (wav path, monotonic start time)."""
    path = tmp / f"bar-tempo-{os.getpid()}-{time.monotonic_ns()}.wav"
    started = time.monotonic()
    # SIGTERM lets pw-record write the wav header sizes on exit. stream.capture.sink records the
    # sink's output, a "<sink>.monitor" target names no node and lands on the microphone.
    run("timeout", "-s", "TERM", str(seconds), "pw-record", "--target", sink,
        "-P", "{ stream.capture.sink = true }",
        "--rate", "44100", "--channels", "1", "--format", "s16", str(path),
        timeout=seconds + 5)
    try:
        with wave.open(str(path)) as wav:
            if wav.getnframes() > 1000:
                return path, started
    except (OSError, EOFError, wave.Error):
        pass
    path.unlink(missing_ok=True)
    return None


def measure(chunks):
    """Tempo over the whole window and the monotonic time of its last beat.

    Beat tracking over sixteen seconds is steady where shorter windows or
    onset autocorrelation are not, so the chunks are joined and tracked at once.
    """
    joined = tmp / f"bar-tempo-window-{os.getpid()}.wav"
    try:
        with wave.open(str(joined), "wb") as out:
            for i, (path, _) in enumerate(chunks):
                with wave.open(str(path)) as src:
                    if i == 0:
                        out.setparams(src.getparams())
                    out.writeframes(src.readframes(src.getnframes()))
        times = [float(t) for t in run("aubiotrack", str(joined), timeout=40).split()]
    except (OSError, EOFError, wave.Error, ValueError):
        return None
    finally:
        joined.unlink(missing_ok=True)
    if len(times) < 8:
        return None

    gaps = sorted(b - a for a, b in zip(times, times[1:]))
    # A missed beat is one double gap and an extra one a half gap, so trim both tails
    cut = max(1, len(gaps) // 6)
    median = statistics.median(gaps[cut:-cut] or gaps)
    if median <= 0:
        return None
    return fold(60.0 / median), chunks[0][1] + times[-1]


def poll():
    while True:
        fields = (run("playerctl", "metadata", "--format", "{{status}}\t{{mpris:trackid}}").split("\t") + [""] * 2)[:2]
        with lock:
            state.update(zip(("status", "track"), fields))
        time.sleep(1)


def analyse():
    chunks = []
    readings = deque(maxlen=HISTORY)
    track = None
    shown = None

    def reset():
        nonlocal shown
        for path, _ in chunks:
            path.unlink(missing_ok=True)
        chunks.clear()
        readings.clear()
        shown = None
        with lock:
            state["bpm"] = None

    while True:
        with lock:
            playing, current = state["status"] == "Playing", state["track"]
        sink = default_sink() if playing else None
        if sink is None:
            reset()
            track = None
            time.sleep(IDLE)
            continue
        if current != track:
            reset()
            track = current

        chunk = record(CHUNK, sink)
        if chunk is None:
            time.sleep(1)
            continue
        chunks.append(chunk)
        while len(chunks) > WINDOW:
            chunks.pop(0)[0].unlink(missing_ok=True)
        if len(chunks) < 2:
            continue

        result = measure(chunks)
        if result:
            readings.append(result[0])
            if len(readings) >= MIN_READINGS:
                shown = settle(readings, shown)
                with lock:
                    state["bpm"], state["beat"] = shown, result[1]


def main():
    for target in (poll, analyse):
        threading.Thread(target=target, daemon=True).start()

    last = None
    while True:
        with lock:
            bpm, beat = state["bpm"], state["beat"]
        if bpm and beat:
            # the beat is a monotonic time, the bar wants a wall clock one
            line = json.dumps({"bpm": round(bpm, 1), "beat": round(time.time() - (time.monotonic() - beat), 3)})
            if line != last:
                print(line, flush=True)
                last = line
        elif last is not None:
            print(json.dumps({"bpm": 0}), flush=True)
            last = None
        time.sleep(0.25)


if __name__ == "__main__":
    main()
