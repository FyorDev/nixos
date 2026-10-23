import QtQuick
import Quickshell.Io

Row {
    readonly property real textX: info.x

    spacing: 30

    Line {
        topPadding: 39
        text: Markup.fromAnsi(Settings.logo)
    }

    Line {
        id: info
    }

    Process {
        id: fastfetch
        command: Settings.fastfetchCommand
        running: true
        stdout: StdioCollector {
            onStreamFinished: info.text = Markup.fromAnsi(text)
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: fastfetch.running = true
    }
}
