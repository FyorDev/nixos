import QtQuick
import Quickshell.Bluetooth

Button {
    id: root

    required property var screen

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property bool powered: adapter?.enabled ?? false

    visible: adapter !== null
    active: Popups.name === "bluetooth" && Popups.screen === screen
    tip: !powered ? "Bluetooth is off" : connected.length === 0 ? "No devices connected" : connected.map(d => d.name + (d.batteryAvailable ? " " + Math.round(d.battery * 100) + "%" : "")).join("\n")
    onClicked: event => {
        if (event.button === Qt.RightButton && adapter)
            adapter.enabled = !adapter.enabled;
        else
            Popups.toggle("bluetooth", screen, root);
    }

    Glyph {
        code: !root.powered ? 0xF00B2 : root.connected.length > 0 ? 0xF00B1 : 0xF00AF
        color: !root.powered ? Settings.overlay0 : Settings.subtext0
    }

    Text {
        visible: root.connected.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.connected.length
        color: Settings.subtext0
        font.family: Settings.font
        font.pixelSize: 13
    }
}
