pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var marks: ["-", "\\", "|", "/"]
    readonly property string mark: marks[(Math.floor(pos) % marks.length + marks.length) % marks.length]

    property real bpm: 0
    property real beat: 0
    property real pos: 0

    // The mark turns one step per beat. It runs on at the current tempo and each new
    // measurement only pulls its phase part of the way to the measured beat, so a
    // re-estimate never makes it jump.
    Timer {
        property double last: Date.now()
        property real synced: 0

        interval: 30
        repeat: true
        running: Players.playing
        onRunningChanged: last = Date.now()
        onTriggered: {
            const now = Date.now();
            const rate = root.bpm > 0 ? root.bpm / 60 : 2;
            root.pos += (now - last) / 1000 * rate;
            last = now;
            if (!(root.bpm > 0 && root.beat > 0)) {
                synced = 0;
            } else if (root.beat !== synced) {
                const ideal = ((now / 1000 - root.beat) * rate) % 1;
                const error = ((ideal - root.pos % 1 + 0.5) % 1 + 1) % 1 - 0.5;
                root.pos += synced === 0 ? error : 0.2 * error;
                synced = root.beat;
            }
        }
    }

    Process {
        command: Settings.tempoCommand
        running: Players.playing
        onRunningChanged: if (!running)
            root.bpm = 0
        stdout: SplitParser {
            onRead: data => {
                try {
                    const reading = JSON.parse(data);
                    root.bpm = reading.bpm ?? 0;
                    root.beat = reading.beat ?? 0;
                } catch (e) {
                    root.bpm = 0;
                }
            }
        }
    }
}
