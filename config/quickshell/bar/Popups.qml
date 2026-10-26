pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string name: ""
    property var screen: null
    property real anchorX: 0

    function toggle(popup, screen, item) {
        if (name === popup && root.screen === screen) {
            close();
            return;
        }
        root.screen = screen;
        anchorX = item.mapToItem(null, 0, 0).x;
        name = popup;
    }

    function close() {
        name = "";
    }
}
