import QtQuick

Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    readonly property real contentWidth: label.implicitWidth
    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    clip: true
    implicitHeight: label.implicitHeight

    Text {
        id: label
        color: Settings.text
        font.family: Settings.font
        font.pixelSize: 13
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on x {
            running: root.overflow > 0 && root.visible
            loops: Animation.Infinite
            PauseAnimation {
                duration: 2500
            }
            NumberAnimation {
                to: -root.overflow
                duration: root.overflow * 40
                easing.type: Easing.InOutSine
            }
            PauseAnimation {
                duration: 2500
            }
            NumberAnimation {
                to: 0
                duration: root.overflow * 40
                easing.type: Easing.InOutSine
            }
        }
    }

    onTextChanged: label.x = 0
}
