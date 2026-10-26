import QtQuick

Button {
    id: root

    required property var screen
    property date now: new Date()

    active: Popups.name === "calendar" && Popups.screen === screen
    leftPadding: 12
    rightPadding: 0
    onClicked: Popups.toggle("calendar", screen, root)

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDate(root.now, "yyyy MM") + Markup.paint("subtext0", Qt.formatDate(root.now, "_MMM")) + Qt.formatDate(root.now, " dd") + Markup.paint("subtext0", Qt.formatDate(root.now, "_ddd")) + " " + ["HH", "mm", "ss"].map(part => Qt.formatTime(root.now, part)).join(Markup.paint("subtext0", ":"))
        textFormat: Text.StyledText
        color: Settings.mauve
        font.family: Settings.font
        font.pixelSize: 14
        font.bold: true
    }

    AnalogClock {
        width: 24
        height: 24
        now: root.now
    }
}
