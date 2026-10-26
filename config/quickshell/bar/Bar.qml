import QtQuick
import Quickshell

Scope {
    id: root

    required property var screen

    PanelWindow {
        id: bar

        screen: root.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Style.barHeight
        color: Settings.mantle

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Style.line
            color: Settings.surface0
        }

        // everything is full height above the bottom line, so highlights run edge to edge
        Item {
            width: parent.width
            height: parent.height - Style.line

            MediaWidget {
                screen: root.screen
                height: parent.height
                maxWidth: parent.width / 2 - centre.width / 2 - 16
            }

            Row {
                id: centre
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                spacing: 6

                ClockWidget {
                    screen: root.screen
                    height: parent.height
                }

                IpText {
                    height: parent.height
                }
            }

            Row {
                anchors.right: parent.right
                height: parent.height

                BluetoothWidget {
                    screen: root.screen
                    height: parent.height
                }

                NetworkWidget {
                    screen: root.screen
                    height: parent.height
                }

                VolumeWidget {
                    screen: root.screen
                    height: parent.height
                }

                BatteryWidget {
                    height: parent.height
                }

                TrayWidget {
                    height: parent.height
                }

                ServiceToggle {
                    height: parent.height
                    unit: "lan-mouse"
                    onCode: 0xF245
                    onTip: "Sharing mouse and keyboard, click to turn off"
                    offTip: "Lan Mouse is off, click to turn on"
                }

                ServiceToggle {
                    height: parent.height
                    unit: "swayidle"
                    onCode: 0xF023
                    offCode: 0xF09C
                    onTip: "Locks after 15 minutes idle, click to turn off"
                    offTip: "Auto lock is off, click to turn on"
                }

                DndToggle {
                    height: parent.height
                }

                PowerWidget {
                    screen: root.screen
                    height: parent.height
                }
            }
        }
    }

    // hangs from the bar, its top border lies over the bar's bottom line
    PopupLayer {
        target: root.screen
        top: Style.barHeight - Style.line
    }
}
