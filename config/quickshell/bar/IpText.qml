import QtQuick

Button {
    leftPadding: 0
    rightPadding: 12
    onClicked: Net.showPublic = !Net.showPublic
    tip: Net.showPublic ? "Public address, click to go back" : "Click for the public address"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Net.local === "" ? "offline" : Net.showPublic ? Net.publicAddress || "?" : Net.local
        color: Net.local === "" ? Settings.red : Settings.subtext0
        font.family: Settings.font
        font.pixelSize: 13
    }
}
