import QtQuick
import Quickshell.Io

Button {
    id: root

    property bool quiet: false

    tip: quiet ? "Do not disturb is on, click to turn off" : "Click for do not disturb"
    onClicked: change.running = true

    Component.onCompleted: check.running = true

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: check.running = true
    }

    Process {
        id: check
        command: [Settings.makoctl, "mode"]
        stdout: StdioCollector {
            onStreamFinished: root.quiet = text.split("\n").includes("do-not-disturb")
        }
    }

    Process {
        id: change
        command: [Settings.makoctl, "mode", "-t", "do-not-disturb"]
        onExited: check.running = true
    }

    Glyph {
        code: root.quiet ? 0xF1F6 : 0xF0F3
        color: root.quiet ? Settings.overlay0 : Settings.mauve
    }
}
