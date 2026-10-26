import QtQuick
import Quickshell.Widgets

Card {
    id: root

    readonly property var player: Players.player

    function clock(seconds) {
        const total = Math.max(0, Math.round(seconds));
        return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0");
    }

    Timer {
        interval: 500
        repeat: true
        running: root.visible && Players.playing
        onTriggered: root.player?.positionChanged()
    }

    Row {
        spacing: 16

        ClippingRectangle {
            width: 120
            height: 120
            color: Settings.surface0

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        Column {
            width: 260
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Marquee {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                font.pixelSize: 16
                font.bold: true
            }

            Marquee {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: Settings.subtext0
            }

            Marquee {
                width: parent.width
                text: root.player?.trackAlbum ?? ""
                font.pixelSize: 11
                color: Settings.overlay1
            }

            Text {
                visible: Tempo.bpm > 0
                text: Math.round(Tempo.bpm) + " bpm"
                color: Settings.mauve
                font.family: Settings.font
                font.pixelSize: 12
            }
        }
    }

    Column {
        width: 396
        spacing: 2

        Slider {
            width: parent.width
            thickness: 2
            enabled: root.player?.canSeek ?? false
            value: (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / root.player.length : 0
            onMoved: v => {
                if (root.player?.canSeek)
                    root.player.position = v * root.player.length;
            }
        }

        Item {
            width: parent.width
            height: 14

            Text {
                text: root.clock(root.player?.position ?? 0)
                color: Settings.subtext0
                font.family: Settings.font
                font.pixelSize: 11
            }

            Text {
                anchors.right: parent.right
                text: root.clock(root.player?.length ?? 0)
                color: Settings.subtext0
                font.family: Settings.font
                font.pixelSize: 11
            }
        }
    }

    Row {
        anchors.horizontalCenter: undefined
        x: (396 - width) / 2
        spacing: 14

        Button {
            id: prev
            padding: 12
            onClicked: root.player?.previous()
            Glyph {
                code: 0xF048
                font.pixelSize: 20
                color: prev.hovered ? Settings.mauve : Settings.subtext0
            }
        }

        Button {
            id: play
            padding: 14
            onClicked: root.player?.togglePlaying()
            Glyph {
                code: Players.playing ? 0xF04C : 0xF04B
                font.pixelSize: 24
                color: play.hovered ? Settings.mauve : Settings.text
            }
        }

        Button {
            id: skip
            padding: 12
            onClicked: root.player?.next()
            Glyph {
                code: 0xF051
                font.pixelSize: 20
                color: skip.hovered ? Settings.mauve : Settings.subtext0
            }
        }
    }

    Spectrum {
        x: (396 - width) / 2
        font.pixelSize: 14
    }
}
