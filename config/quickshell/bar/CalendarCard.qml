import QtQuick

Card {
    id: root

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()

    // Monday first, six rows of seven
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() + 6) % 7;
        return Array.from({
            length: 42
        }, (_, i) => new Date(year, month, 1 - lead + i));
    }

    function isoWeek(date) {
        const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const weekday = day.getUTCDay() || 7;
        day.setUTCDate(day.getUTCDate() + 4 - weekday);
        const start = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
        return Math.ceil(((day - start) / 86400000 + 1) / 7);
    }

    function step(by) {
        const next = new Date(year, month + by, 1);
        year = next.getFullYear();
        month = next.getMonth();
    }

    MouseArea {
        width: grid.implicitWidth
        height: grid.implicitHeight
        onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)

        Column {
            id: grid
            spacing: 8

            Row {
                width: 7 * 34 + 30

                Button {
                    padding: 8
                    onClicked: root.step(-1)
                    Glyph {
                        code: 0xF053
                        color: Settings.subtext0
                    }
                }

                Text {
                    width: parent.width - 2 * 32
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                    color: Settings.mauve
                    font.family: Settings.font
                    font.pixelSize: 15
                    font.bold: true
                }

                Button {
                    padding: 8
                    onClicked: root.step(1)
                    Glyph {
                        code: 0xF054
                        color: Settings.subtext0
                    }
                }
            }

            Grid {
                columns: 8
                rowSpacing: 2
                columnSpacing: 0

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su", "wk"]

                    Text {
                        required property string modelData

                        width: modelData === "wk" ? 30 : 34
                        height: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: modelData === "wk" ? Settings.blue : Settings.subtext0
                        font.family: Settings.font
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: 48

                    Item {
                        id: cell

                        required property int index

                        readonly property bool weekCell: index % 8 === 7
                        readonly property date day: root.cells[Math.floor(index / 8) * 7 + Math.min(index % 8, 6)]
                        readonly property bool isToday: !weekCell && day.toDateString() === root.today.toDateString()

                        width: weekCell ? 30 : 34
                        height: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 26
                            color: Settings.red
                            visible: cell.isToday
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cell.weekCell ? root.isoWeek(cell.day) : cell.day.getDate()
                            color: cell.isToday ? Settings.crust : cell.weekCell ? Settings.blue : cell.day.getMonth() === root.month ? Settings.text : Settings.overlay0
                            font.family: Settings.font
                            font.pixelSize: cell.weekCell ? 11 : 13
                            font.bold: cell.isToday
                        }
                    }
                }
            }
        }
    }
}
