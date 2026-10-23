import QtQuick
import Quickshell.Io

Column {
    id: root

    property var weather: null
    property date now: new Date()
    readonly property var hours: weather === null ? [] : weather.hours.filter(h => new Date(h.time).getTime() + 3600000 > now.getTime()).slice(0, 6)
    readonly property var current: hours.length > 0 ? hours[0] : null

    // a doubled letter is the night version
    function icon(code) {
        const night = {
            a: 0xF0594,
            b: 0xF0F31, j: 0xF0F31, o: 0xF0F31, r: 0xF0F31
        };
        const day = {
            a: 0xF0599,
            b: 0xF0595, j: 0xF0595, o: 0xF0595, r: 0xF0595,
            c: 0xF0590, p: 0xF0590,
            d: 0xF0591, n: 0xF0591,
            f: 0xF0F33, h: 0xF0F33,
            k: 0xF0597, m: 0xF0597, q: 0xF0597,
            l: 0xF0596,
            g: 0xF0F32,
            s: 0xF067E,
            i: 0xF0598, t: 0xF0598, u: 0xF0598, v: 0xF0598,
            w: 0xF067F
        };
        const c = code.toLowerCase();
        return String.fromCodePoint((c.length > 1 && night[c[0]]) || day[c[0]] || 0xF0590);
    }

    function value(text) {
        return Markup.paint("peach", text);
    }

    component Glyph: Line {
        color: Settings.mauve
        textFormat: Text.PlainText
    }

    component Cell: Line {
        width: 64
        horizontalAlignment: Text.AlignHCenter
    }

    component Strip: Row {
        property alias model: repeater.model
        property alias delegate: repeater.delegate

        anchors.right: parent.right

        Repeater {
            id: repeater
        }
    }

    visible: current !== null
    spacing: 6

    Row {
        anchors.right: parent.right
        spacing: 8

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.current ? root.icon(root.current.icon) : ""
        }

        Line {
            anchors.verticalCenter: parent.verticalCenter
            text: root.current ? root.value(root.current.temperature.toFixed(1) + "\u00b0") : ""
        }

        Line {
            anchors.verticalCenter: parent.verticalCenter
            text: root.current ? "feels " + root.value(root.current.feel.toFixed(1) + "\u00b0") : ""
        }
    }

    Strip {
        model: root.hours

        delegate: Column {
            required property var modelData

            Cell {
                text: modelData.time.substring(11, 16)
            }

            Cell {
                horizontalAlignment: Text.AlignLeft
                text: Markup.paint("mauve", root.icon(modelData.icon)) + " " + root.value(modelData.mm.toFixed(1))
            }

            Cell {
                text: root.value(modelData.temperature.toFixed(0) + "\u00b0")
            }
        }
    }

    Strip {
        model: root.weather === null ? [] : root.weather.days

        delegate: Column {
            required property var modelData

            Cell {
                text: Qt.formatDate(new Date(modelData.day + "T00:00"), "ddd")
            }

            Cell {
                horizontalAlignment: Text.AlignLeft
                text: Markup.paint("mauve", root.icon(modelData.icon)) + " " + root.value(modelData.mm.toFixed(1))
            }

            Cell {
                text: root.value(modelData.min.toFixed(0) + "-" + modelData.max.toFixed(0) + "\u00b0")
            }
        }
    }

    FileView {
        path: Settings.weatherFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.weather = JSON.parse(text());
            } catch (e) {
                root.weather = null;
            }
        }
        onLoadFailed: root.weather = null
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
