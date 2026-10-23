import QtQuick

Item {
    id: face

    property date now: new Date()
    readonly property real unit: width / (2 * 13.3)

    Repeater {
        model: [
            {
                turn: (face.now.getHours() % 12 + face.now.getMinutes() / 60) * 30,
                from: 0,
                to: 6,
                thickness: 2.8,
                color: Settings.mauve
            },
            {
                turn: (face.now.getMinutes() + face.now.getSeconds() / 60) * 6,
                from: 7.4,
                to: 10.4,
                thickness: 3,
                color: Settings.subtext0
            },
            {
                turn: face.now.getSeconds() * 6,
                from: 11.8,
                to: 13.3,
                thickness: 3,
                color: Settings.subtext0
            }
        ]

        Rectangle {
            required property var modelData

            x: face.width / 2 - width / 2
            y: face.height / 2 - modelData.to * face.unit
            width: modelData.thickness * face.unit
            height: (modelData.to - modelData.from) * face.unit
            color: modelData.color
            antialiasing: true
            transform: Rotation {
                origin.x: modelData.thickness * face.unit / 2
                origin.y: modelData.to * face.unit
                angle: modelData.turn
            }
        }
    }
}
