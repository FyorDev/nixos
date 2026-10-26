import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var target
    property real top: 0

    // the window's own screen changes when it maps, so compare against the bar's
    screen: target
    visible: Popups.name !== "" && Popups.screen === target
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bar-popup"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: Popups.close()
    }

    // Popups.name picks the card: "calendar" is CalendarCard.qml
    Loader {
        x: Math.max(0, Math.min(Popups.anchorX, parent.width - width))
        y: root.top
        opacity: item ? 1 : 0
        source: Popups.name === "" ? "" : Popups.name[0].toUpperCase() + Popups.name.slice(1) + "Card.qml"

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }
    }
}
