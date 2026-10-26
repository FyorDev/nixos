import QtQuick

Button {
    id: root

    property int code: 0
    property string label: ""
    property string keys: ""

    width: 300
    padding: 12

    Glyph {
        width: 20
        code: root.code
        color: Settings.subtext0
    }

    // fills the row up to the shortcut, so the shortcut sits at the right edge
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - root.leftPadding - root.rightPadding - 20 - shortcut.width - 12
        text: root.label
        color: Settings.text
        elide: Text.ElideRight
        font.family: Settings.font
        font.pixelSize: 13
    }

    Text {
        id: shortcut
        anchors.verticalCenter: parent.verticalCenter
        text: root.keys
        color: Settings.subtext0
        opacity: root.hovered ? 1 : 0
        font.family: Settings.font
        font.pixelSize: 11

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }
}
