import QtQuick

Button {
    id: root

    required property var screen

    active: Popups.name === "power" && Popups.screen === screen
    onClicked: Popups.toggle("power", screen, root)

    Glyph {
        code: 0xF011
        color: root.hovered || root.active ? Settings.red : Settings.maroon
    }
}
