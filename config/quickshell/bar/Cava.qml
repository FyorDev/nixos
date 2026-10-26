pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int count: 40
    readonly property int range: 32
    property var levels: Array(count).fill(0)

    Process {
        command: Settings.cavaCommand
        running: Players.playing
        onRunningChanged: if (!running)
            root.levels = Array(root.count).fill(0)
        stdout: SplitParser {
            onRead: data => {
                const values = data.split(";").filter(v => v !== "").map(Number);
                if (values.length === root.count)
                    root.levels = values;
            }
        }
    }
}
