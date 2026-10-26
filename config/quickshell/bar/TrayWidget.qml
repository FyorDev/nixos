import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root

    spacing: 0

    Repeater {
        // the network and bluetooth applets are shown by their own widgets
        model: SystemTray.items.values.filter(item => item.id !== "blueman" && item.id !== "nm-applet")

        Button {
            id: entry

            required property var modelData

            height: parent.height
            padding: 6
            tip: modelData.tooltipTitle || modelData.title
            onClicked: event => {
                if (event.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (event.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) {
                        const spot = mapToItem(null, 0, height);
                        modelData.display(QsWindow.window, spot.x, spot.y);
                    }
                } else {
                    modelData.activate();
                }
            }
            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            IconImage {
                width: 18
                height: 18
                source: entry.modelData.icon
            }
        }
    }
}
