pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool recording: false
    property bool mirroring: false

    function refresh() {
        check.running = true;
    }

    // not the screenrecord toggle, which would start a new recording if this one just ended
    function stopRecording() {
        Quickshell.execDetached([Settings.pkill, "-INT", "-x", "wf-recorder"]);
        recording = false;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    Process {
        id: check
        command: [Settings.pgrep, "-l", "-x", "wf-recorder|wl-mirror"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").map(line => line.split(" ")[1]);
                root.recording = names.includes("wf-recorder");
                root.mirroring = names.includes("wl-mirror");
            }
        }
    }
}
