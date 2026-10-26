import QtQuick
import Quickshell

Card {
    id: root

    padding: 8

    Column {
        spacing: 2

        Repeater {
            model: [
                {
                    label: "Lock screen",
                    code: 0xF023,
                    command: ["lock-screen"]
                },
                {
                    label: "Suspend",
                    code: 0xF186,
                    command: ["systemctl", "suspend"]
                },
                {
                    label: "Log out",
                    code: 0xF08B,
                    command: [Settings.niri, "msg", "action", "quit", "--skip-confirmation"]
                },
                {
                    label: "Restart",
                    code: 0xF021,
                    command: ["systemctl", "reboot"],
                    danger: true
                },
                {
                    label: "Shut down",
                    code: 0xF011,
                    command: ["systemctl", "poweroff"],
                    danger: true
                }
            ]

            Button {
                id: entry

                required property var modelData

                width: 190
                padding: 12
                onClicked: {
                    Popups.close();
                    Quickshell.execDetached(modelData.command);
                }

                Glyph {
                    width: 20
                    code: entry.modelData.code
                    color: entry.modelData.danger && entry.hovered ? Settings.red : Settings.subtext0
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.label
                    color: entry.modelData.danger && entry.hovered ? Settings.red : Settings.text
                    font.family: Settings.font
                    font.pixelSize: 13
                }
            }
        }
    }
}
