import QtQuick

Column {
    id: tree

    property var rows: []
    default property alias content: extra.data

    function key(branch, code, label) {
        return (branch === "" ? "" : " " + branch) + String.fromCodePoint(code) + " " + label;
    }

    function line(key, value) {
        return Markup.paint("mauve", key.replace(/ /g, "&nbsp;")) + " " + value;
    }

    Line {
        textFormat: Text.PlainText
        text: " \u250c" + "\u2500".repeat(24) + "\u2510"
        color: Settings.mauve
    }

    Repeater {
        model: tree.rows

        Line {
            required property var modelData
            text: tree.line(modelData[0], modelData[1])
        }
    }

    Column {
        id: extra
    }

    Line {
        textFormat: Text.PlainText
        text: " \u2514" + "\u2500".repeat(24) + "\u2518"
        color: Settings.mauve
    }
}
