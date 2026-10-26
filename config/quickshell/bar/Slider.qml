import QtQuick

Item {
    id: root

    property real value: 0
    property color color: Settings.mauve
    property bool enabled: true
    property real thickness: 3
    readonly property bool engaged: enabled && (mouse.containsMouse || mouse.pressed)

    signal moved(real value)

    function at(x) {
        return Math.max(0, Math.min(1, x / width));
    }

    implicitHeight: 14

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.engaged ? root.thickness + 2 : root.thickness
        color: Settings.surface1

        Behavior on height {
            NumberAnimation {
                duration: 100
            }
        }

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            color: root.color
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.moved(root.at(event.x))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.at(event.x));
        }
    }
}
