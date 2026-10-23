import QtQuick
import Quickshell.Services.Mpris

Column {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    component Button: Text {
        id: button

        signal clicked

        color: mouse.containsMouse ? Settings.mauve : Settings.subtext0
        font.family: Settings.font
        font.pixelSize: 24

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    visible: player !== null
    spacing: 16

    Image {
        id: cover
        width: 128
        height: 128
        source: root.player?.trackArtUrl ?? ""
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Row {
        x: (cover.width - width) / 2
        spacing: 28

        Button {
            text: String.fromCodePoint(0xF048)
            onClicked: root.player.previous()
        }

        Button {
            text: String.fromCodePoint(root.player?.isPlaying ? 0xF04C : 0xF04B)
            onClicked: root.player.togglePlaying()
        }

        Button {
            text: String.fromCodePoint(0xF051)
            onClicked: root.player.next()
        }
    }

    Visualizer {
        running: root.player?.isPlaying ?? false
    }
}
