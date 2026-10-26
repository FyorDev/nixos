import QtQuick
import Quickshell

Rectangle {
    id: root

    property bool active: false
    property real padding: 8
    property real leftPadding: padding
    property real rightPadding: padding
    property string tip: ""
    readonly property alias hovered: mouse.containsMouse
    default property alias content: row.data

    signal clicked(var event)
    signal wheel(var event)

    implicitWidth: row.implicitWidth + leftPadding + rightPadding
    implicitHeight: 30
    color: hovered || active ? Settings.surface0 : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: root.leftPadding
        spacing: 6
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Style.accent
        color: Settings.mauve
        visible: root.active
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event)
        onWheel: event => root.wheel(event)
    }

    Timer {
        id: delay
        interval: 500
        running: root.hovered && root.tip !== "" && !root.active
    }

    Loader {
        active: root.hovered && !delay.running && root.tip !== "" && !root.active

        sourceComponent: PopupWindow {
            anchor.item: root
            anchor.rect.y: root.height
            visible: true
            implicitWidth: label.implicitWidth + 20
            implicitHeight: label.implicitHeight + 12
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Settings.mantle
                border.width: Style.line
                border.color: Settings.surface0

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.tip
                    color: Settings.text
                    font.family: Settings.font
                    font.pixelSize: 12
                }
            }
        }
    }
}
