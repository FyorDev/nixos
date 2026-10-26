import QtQuick

Card {
    id: root

    Row {
        spacing: 10

        Button {
            id: mute
            onClicked: Audio.toggleMute()
            Glyph {
                code: Audio.muted || Audio.volume === 0 ? 0xF026 : Audio.volume < 0.5 ? 0xF027 : 0xF028
                color: Audio.muted ? Settings.overlay0 : Settings.sapphire
            }
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 220
            value: Audio.volume / 1.5
            color: Audio.muted ? Settings.overlay0 : Settings.sapphire
            onMoved: v => Audio.setVolume(v * 1.5)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(Audio.volume * 100) + "%"
            color: Settings.text
            font.family: Settings.font
            font.pixelSize: 13
        }
    }

    Rectangle {
        width: 300
        height: 1
        color: Settings.surface1
    }

    Column {
        spacing: 2

        Repeater {
            model: Audio.sinks

            Button {
                id: entry

                required property var modelData

                readonly property bool current: Audio.sink === modelData

                width: 300
                padding: 10
                onClicked: Audio.select(modelData)

                Glyph {
                    code: entry.current ? 0xF111 : 0xF10C
                    font.pixelSize: 10
                    color: entry.current ? Settings.mauve : Settings.overlay0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    width: 260
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.name(entry.modelData)
                    elide: Text.ElideRight
                    color: entry.current ? Settings.text : Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 13
                }
            }
        }
    }
}
