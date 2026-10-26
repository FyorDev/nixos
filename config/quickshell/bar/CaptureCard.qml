import QtQuick
import Quickshell

Card {
    id: root

    // the menu has to be off screen before anything captures it
    function run(command) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec \"$@\"", "sh"].concat(command));
        Popups.close();
    }

    padding: 8
    Component.onCompleted: Capture.refresh()

    Column {
        spacing: 2

        Repeater {
            model: [
                {
                    label: "Screenshot an area",
                    code: 0xF125,
                    keys: "Print",
                    command: [Settings.niri, "msg", "action", "screenshot"]
                },
                {
                    label: "Screenshot the screen",
                    code: 0xF108,
                    keys: "Ctrl+Print",
                    command: [Settings.niri, "msg", "action", "screenshot-screen"]
                },
                {
                    label: "Screenshot a window",
                    code: 0xF2D0,
                    keys: "Alt+Print",
                    command: [Settings.niri, "msg", "action", "screenshot-window"]
                },
                {
                    label: "Annotate an area",
                    code: 0xF040,
                    keys: "Mod+Shift+Print",
                    command: ["screenshot-annotate"]
                },
                {
                    label: "Copy text from an area",
                    code: 0xF031,
                    keys: "Mod+Print",
                    command: ["screenshot-ocr"]
                }
            ]

            MenuEntry {
                required property var modelData

                code: modelData.code
                label: modelData.label
                keys: modelData.keys
                onClicked: root.run(modelData.command)
            }
        }

        // while recording, the bar button itself stops it
        Separator {
            visible: !Capture.recording
        }

        MenuEntry {
            visible: !Capture.recording
            code: 0xF03D
            label: "Record an area"
            keys: "Shift+Print"
            onClicked: root.run(["screenrecord"])
        }

        Separator {}

        MenuEntry {
            code: Capture.mirroring ? 0xF28D : 0xF26C
            label: Capture.mirroring ? "Stop mirroring" : "Mirror this display"
            keys: "Mod+Ctrl+P"
            onClicked: root.run(["mirror-display"])
        }

        // wl-present commands for the running mirror
        Repeater {
            model: Capture.mirroring ? [
                {
                    label: "Freeze or unfreeze",
                    code: 0xF2DC,
                    command: "toggle-freeze"
                },
                {
                    label: "Mirror an area",
                    code: 0xF125,
                    command: "set-region"
                },
                {
                    label: "Mirror the whole display",
                    code: 0xF065,
                    command: "unset-region"
                },
                {
                    label: "Change the mirrored display",
                    code: 0xF0EC,
                    command: "set-output"
                },
                {
                    label: "Change where it is shown",
                    code: 0xF108,
                    command: "fullscreen-output"
                }
            ] : []

            MenuEntry {
                required property var modelData

                code: modelData.code
                label: modelData.label
                onClicked: root.run(["mirror-display", modelData.command])
            }
        }
    }

    component Separator: Item {
        width: 300
        height: 9

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 24
            height: Style.line
            color: Settings.surface0
        }
    }
}
