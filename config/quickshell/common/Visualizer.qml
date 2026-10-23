import QtQuick
import Quickshell.Io

Line {
    id: root

    property bool running: false
    property var levels: []

    onRunningChanged: if (!running)
        levels = []

    textFormat: Text.PlainText
    text: levels.map(v => {
        const level = Math.round(8 * Math.pow(Math.min(1, v / 32), 0.55));
        return level ? String.fromCodePoint(0x2580 + level) : " ";
    }).join("")

    Process {
        command: Settings.cavaCommand
        running: root.running
        stdout: SplitParser {
            onRead: data => {
                const values = data.split(";").filter(v => v !== "").map(Number);
                if (values.length === 40)
                    root.levels = values;
            }
        }
    }
}
