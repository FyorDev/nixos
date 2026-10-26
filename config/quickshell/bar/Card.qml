import QtQuick

Rectangle {
    id: root

    default property alias content: holder.data
    property real padding: 16

    implicitWidth: holder.implicitWidth + 2 * padding
    implicitHeight: holder.implicitHeight + 2 * padding
    color: Settings.mantle
    border.width: Style.line
    border.color: Settings.surface0

    Column {
        id: holder
        x: root.padding
        y: root.padding
        spacing: 12
    }
}
