import QtQuick
import Quickshell.Bluetooth

Card {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var known: Bluetooth.devices.values.filter(d => d.paired).sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name))

    Row {
        spacing: 10

        Text {
            width: 270
            anchors.verticalCenter: parent.verticalCenter
            text: root.adapter?.name ?? "Bluetooth"
            color: Settings.mauve
            font.family: Settings.font
            font.pixelSize: 15
            font.bold: true
        }

        Button {
            id: power
            onClicked: root.adapter.enabled = !root.adapter.enabled
            Glyph {
                code: 0xF011
                color: root.adapter?.enabled ? Settings.blue : Settings.overlay0
            }
        }
    }

    Rectangle {
        width: 320
        height: 1
        color: Settings.surface1
    }

    Column {
        spacing: 2

        Repeater {
            model: root.known

            Button {
                id: entry

                required property var modelData

                width: 320
                padding: 10
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()

                Glyph {
                    width: 20
                    code: entry.modelData.connected ? 0xF00B1 : 0xF00AF
                    color: entry.modelData.connected ? Settings.blue : Settings.overlay0
                }

                Text {
                    width: 200
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.name
                    elide: Text.ElideRight
                    color: entry.modelData.connected ? Settings.text : Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 13
                }

                Text {
                    width: 60
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: entry.modelData.state === BluetoothDeviceState.Connecting ? "..." : entry.modelData.batteryAvailable ? Math.round(entry.modelData.battery * 100) + "%" : ""
                    color: Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 12
                }
            }
        }
    }
}
