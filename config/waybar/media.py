"""Left side of the bar as JSON streams: "text" is title, artist and tempo, "bars" the spectrum.

Only the default sink's monitor is ever recorded, so this never touches a microphone.
Tempo is measured with aubiotrack over a sliding window because no player publishes it.
They are separate modules so that waybar ellipsizes the text first and only drops the bars
when there is no room left. Run with "toggle" to collapse or expand the text.
"""

import html
import json
import os
import statistics
import subprocess
import sys
import tempfile
import threading
import time
import wave
from collections import deque
from pathlib import Path

FPS = 60
IDLE = 2.0
CHUNK = 4.0
WINDOW = 4
HISTORY = 30
MIN_READINGS = 3
TOLERANCE = 3.0
BPM_MIN, BPM_MAX = 90.0, 180.0
BARS = 40
RANGE = 32
GAMMA = 0.55

SPINNER = ["—", "\\", "|", "/"]
LEVELS = " " + "".join(chr(0x2580 + i) for i in range(1, 9))

# Mono, or cava mirrors the bars between channels. Low noise reduction and high gravity make them snap.
CAVA_CONF = """[general]
framerate = {fps}
bars = {bars}
sensitivity = 150
[input]
method = pipewire
source = {source}
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = {range}
bar_delimiter = 59
channels = mono
mono_option = average
[smoothing]
noise_reduction = 0.20
gravity = 180
"""

state = {
    "status": "", "title": "", "artist": "", "album": "", "track": "",
    "bpm": None, "beat": None, "levels": [0] * BARS,
}
lock = threading.Lock()
tmp = Path(tempfile.gettempdir())
collapsed = Path(os.environ.get("XDG_RUNTIME_DIR", tmp)) / "waybar-media-collapsed"


def run(*args, timeout=2):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def sink_monitor():
    for line in run("wpctl", "inspect", "@DEFAULT_AUDIO_SINK@").splitlines():
        if "node.name" in line:
            return line.split("=", 1)[1].strip().strip('"') + ".monitor"
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


def record(seconds, source):
    """One chunk of the sink's audio as (wav path, monotonic start time)."""
    path = tmp / f"waybar-media-{os.getpid()}-{time.monotonic_ns()}.wav"
    started = time.monotonic()
    # SIGTERM lets pw-record write the wav header sizes on exit
    run("timeout", "-s", "TERM", str(seconds), "pw-record", "--target", source,
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
    joined = tmp / f"waybar-window-{os.getpid()}.wav"
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
    keys = ("status", "title", "artist", "album", "track")
    fmt = "\t".join("{{%s}}" % k for k in ("status", "title", "artist", "album", "mpris:trackid"))
    while True:
        fields = (run("playerctl", "metadata", "--format", fmt).split("\t") + [""] * 5)[:5]
        with lock:
            state.update(zip(keys, fields))
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
        source = sink_monitor() if playing else None
        if source is None:
            reset()
            track = None
            time.sleep(IDLE)
            continue
        if current != track:
            reset()
            track = current

        chunk = record(CHUNK, source)
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


def spectrum():
    conf = tmp / f"waybar-cava-{os.getpid()}.conf"
    while True:
        source = sink_monitor()
        if source is None:
            time.sleep(IDLE)
            continue
        conf.write_text(CAVA_CONF.format(fps=FPS, bars=BARS, range=RANGE, source=source))
        cava = subprocess.Popen(["cava", "-p", str(conf)], stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)
        for line in cava.stdout:
            try:
                values = [int(v) for v in line.split(";") if v.strip()]
            except ValueError:
                continue
            if len(values) == BARS:
                with lock:
                    state["levels"] = values
        cava.wait()
        time.sleep(1)


class Spinner:
    """A mark that turns one step per beat.

    The position advances continuously at the current tempo and each new
    measurement only pulls its phase part of the way toward the measured beat,
    so a re-estimate or a tempo change never makes the mark jump.
    """

    GAIN = 0.2

    def __init__(self):
        self.pos = 0.0
        self.last = time.monotonic()
        self.synced = None

    def mark(self, bpm, beat):
        now = time.monotonic()
        rate = bpm / 60.0 if bpm else 2.0
        self.pos += (now - self.last) * rate
        self.last = now

        if not (bpm and beat):
            self.synced = None
        elif beat != self.synced:
            ideal = ((now - beat) * rate) % 1.0
            error = (ideal - self.pos % 1.0 + 0.5) % 1.0 - 0.5
            self.pos += error if self.synced is None else self.GAIN * error
            self.synced = beat
        return SPINNER[int(self.pos) % len(SPINNER)]


def level(value):
    """Bar character for a raw cava value, lifted so quiet bars still move."""
    return LEVELS[round(8 * min(1.0, value / RANGE) ** GAMMA)]


def tooltip(s):
    lines = [p for p in (s["title"], s["artist"], s["album"]) if p]
    if s["bpm"]:
        lines.append(f"{s['bpm']:.1f} BPM, measured from the audio")
    return html.escape("\n".join(lines))


def render_text(s, mark):
    parts = [s["title"]]
    if s["artist"]:
        parts += [mark, s["artist"]]
    if s["bpm"]:
        parts += [mark, f"{s['bpm']:.0f}bpm"]
    text = "" if collapsed.exists() else html.escape(" ".join(p for p in parts if p))
    return {"text": text, "class": "playing", "tooltip": tooltip(s)}


def render_bars(s):
    return {"text": "".join(level(v) for v in s["levels"]), "class": "playing", "tooltip": tooltip(s)}


def main():
    mode = (sys.argv[1:] or ["text"])[0]
    if mode == "toggle":
        if collapsed.exists():
            collapsed.unlink()
        else:
            collapsed.touch()
        return

    workers = {"text": (poll, analyse), "bars": (poll, spectrum)}[mode]
    for target in workers:
        threading.Thread(target=target, daemon=True).start()

    spinner = Spinner()
    last = None
    while True:
        with lock:
            s = dict(state)
        if s["status"] != "Playing":
            out = {"text": "", "class": "idle", "tooltip": "Nothing playing"}
        elif mode == "bars":
            out = render_bars(s)
        else:
            out = render_text(s, spinner.mark(s["bpm"], s["beat"]))
        line = json.dumps(out)
        if line != last:
            print(line, flush=True)
            last = line
        time.sleep(1 / FPS)


if __name__ == "__main__":
    main()
