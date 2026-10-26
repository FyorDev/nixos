import QtQuick

Text {
    property var levels: Cava.levels

    textFormat: Text.PlainText
    text: levels.map(v => {
        const level = Math.round(8 * Math.pow(Math.min(1, v / Cava.range), 0.55));
        return level ? String.fromCodePoint(0x2580 + level) : " ";
    }).join("")
    color: Settings.subtext0
    font.family: Settings.font
    font.pixelSize: 11
}
