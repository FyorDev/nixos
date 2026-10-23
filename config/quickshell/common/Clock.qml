import QtQuick

Column {
    id: clock

    property date now: new Date()

    spacing: 6

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    AnalogClock {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 96
        height: width
        now: clock.now
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ["HH", "mm", "ss"].map(part => Qt.formatTime(clock.now, part)).join(Markup.paint("subtext0", ":"))
        textFormat: Text.StyledText
        color: Settings.mauve
        font.family: Settings.font
        font.pixelSize: 96
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.now, "yyyy MM") + Markup.paint("subtext0", Qt.formatDate(clock.now, "_MMM")) + Qt.formatDate(clock.now, " dd") + Markup.paint("subtext0", Qt.formatDate(clock.now, "_ddd"))
        textFormat: Text.StyledText
        color: Settings.mauve
        font.family: Settings.font
        font.pixelSize: 18
        font.bold: true
    }
}
