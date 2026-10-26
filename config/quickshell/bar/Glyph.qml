import QtQuick

Text {
    property int code: 0

    text: code ? String.fromCodePoint(code) : ""
    color: Settings.text
    font.family: Settings.font
    font.pixelSize: 15
    verticalAlignment: Text.AlignVCenter
}
