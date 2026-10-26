import QtQuick
import Quickshell.Io

Button {
    id: root

    property string unit: ""
    property int onCode: 0
    property int offCode: onCode
    property string onTip: ""
    property string offTip: ""
    property bool on: false

    tip: on ? onTip : offTip
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
        command: ["systemctl", "--user", "is-active", "--quiet", root.unit]
        onExited: code => root.on = code === 0
    }

    Process {
        id: change
        command: ["systemctl", "--user", root.on ? "stop" : "start", root.unit]
        onExited: check.running = true
    }

    Glyph {
        code: root.on ? root.onCode : root.offCode
        color: root.on ? Settings.mauve : Settings.overlay0
    }
}
