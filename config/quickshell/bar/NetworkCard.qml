import QtQuick
import Quickshell.Networking

Card {
    id: root

    property var asking: null

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.filter(d => d.type === DeviceType.Wired)
    readonly property var networks: wifi ? wifi.networks.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength).slice(0, 8) : []

    function pick(network) {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            asking = asking === network ? null : network;
        }
    }

    Component.onCompleted: if (wifi)
        wifi.scannerEnabled = true
    Component.onDestruction: if (wifi)
        wifi.scannerEnabled = false

    Row {
        spacing: 10

        Text {
            width: 300
            anchors.verticalCenter: parent.verticalCenter
            text: Net.local === "" ? "Offline" : Net.wired ? "Wired" : Net.network?.name ?? "Network"
            color: Settings.mauve
            font.family: Settings.font
            font.pixelSize: 15
            font.bold: true
        }

        Button {
            visible: root.wifi !== null
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            Glyph {
                code: Networking.wifiEnabled ? 0xF0928 : 0xF05AA
                color: Networking.wifiEnabled ? Settings.green : Settings.overlay0
            }
        }
    }

    Rectangle {
        width: 350
        height: 1
        color: Settings.surface1
    }

    Column {
        spacing: 2

        Repeater {
            model: root.wired

            Row {
                id: cable

                required property var modelData

                leftPadding: 10
                spacing: 6
                height: 28

                Glyph {
                    width: 20
                    anchors.verticalCenter: parent.verticalCenter
                    code: 0xF0200
                    color: cable.modelData.hasLink ? Settings.green : Settings.overlay0
                }

                Text {
                    width: 240
                    anchors.verticalCenter: parent.verticalCenter
                    text: cable.modelData.name
                    color: cable.modelData.hasLink ? Settings.text : Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 13
                }

                Text {
                    width: 70
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: cable.modelData.hasLink && cable.modelData.linkSpeed > 0 ? cable.modelData.linkSpeed + " Mb/s" : cable.modelData.hasLink ? "linked" : "no cable"
                    color: Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 12
                }
            }
        }

        Repeater {
            model: Networking.wifiEnabled ? root.networks : []

            Column {
                id: entry

                required property var modelData

                spacing: 2

                Button {
                    width: 350
                    padding: 10
                    onClicked: root.pick(entry.modelData)

                    Glyph {
                        width: 20
                        code: [0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(3, Math.floor(entry.modelData.signalStrength * 4))]
                        color: entry.modelData.connected ? Settings.green : Settings.overlay1
                    }

                    Text {
                        width: 230
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.name
                        elide: Text.ElideRight
                        color: entry.modelData.connected ? Settings.text : Settings.subtext0
                        font.family: Settings.font
                        font.pixelSize: 13
                        font.bold: entry.modelData.connected
                    }

                    Glyph {
                        width: 20
                        code: entry.modelData.security === WifiSecurityType.Open ? 0 : 0xF023
                        font.pixelSize: 11
                        color: Settings.overlay1
                    }

                    Text {
                        width: 46
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: entry.modelData.stateChanging ? "..." : Math.round(entry.modelData.signalStrength * 100) + "%"
                        color: Settings.subtext0
                        font.family: Settings.font
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    visible: root.asking === entry.modelData
                    width: 350
                    height: 32
                    color: Settings.surface0
                    border.width: 1
                    border.color: field.activeFocus ? Settings.mauve : Settings.surface1

                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Settings.text
                        font.family: Settings.font
                        font.pixelSize: 13
                        focus: parent.visible
                        onAccepted: {
                            entry.modelData.connectWithPsk(text);
                            text = "";
                            root.asking = null;
                        }

                        Text {
                            visible: field.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password"
                            color: Settings.overlay0
                            font: field.font
                        }
                    }
                }
            }
        }
    }
}
