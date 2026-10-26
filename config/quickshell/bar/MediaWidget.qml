import QtQuick

Item {
    id: root

    required property var screen
    property real maxWidth: 640
    readonly property var player: Players.player
    readonly property string line: {
        const parts = [player?.trackTitle ?? ""];
        if (player?.trackArtist)
            parts.push(Tempo.mark, player.trackArtist);
        if (Tempo.bpm > 0)
            parts.push(Tempo.mark, Math.round(Tempo.bpm) + "bpm");
        return parts.filter(p => p !== "").join(" ");
    }

    visible: player !== null
    implicitWidth: row.implicitWidth

    Row {
        id: row
        height: parent.height
        spacing: 6

        Button {
            id: cover
            height: parent.height
            padding: 0
            active: Popups.name === "media" && Popups.screen === root.screen
            onClicked: event => {
                if (event.button === Qt.RightButton || !root.player?.canRaise)
                    Popups.toggle("media", root.screen, cover);
                else
                    root.player.raise();
            }

            Item {
                width: cover.height
                height: cover.height
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: Settings.surface0
                }

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Glyph {
                    anchors.centerIn: parent
                    code: 0xF001
                    color: Settings.subtext0
                    visible: !(root.player?.trackArtUrl)
                }
            }
        }

        Row {
            id: controls
            height: parent.height

            Button {
                id: prev
                height: parent.height
                padding: 6
                onClicked: root.player?.previous()
                Glyph {
                    code: 0xF048
                    color: prev.hovered ? Settings.mauve : Settings.subtext0
                }
            }

            Button {
                id: play
                height: parent.height
                padding: 6
                onClicked: root.player?.togglePlaying()
                Glyph {
                    code: Players.playing ? 0xF04C : 0xF04B
                    color: play.hovered ? Settings.mauve : Settings.text
                }
            }

            Button {
                id: skip
                height: parent.height
                padding: 6
                onClicked: root.player?.next()
                Glyph {
                    code: 0xF051
                    color: skip.hovered ? Settings.mauve : Settings.subtext0
                }
            }
        }

        MouseArea {
            width: Math.min(title.contentWidth, Math.max(80, root.maxWidth - cover.width - controls.width - (spectrum.visible ? spectrum.width : 0) - 3 * row.spacing))
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: Popups.toggle("media", root.screen, cover)
            onWheel: event => event.angleDelta.y > 0 ? root.player?.next() : root.player?.previous()

            Marquee {
                id: title
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                text: root.line
                color: Settings.subtext0
            }
        }

        Spectrum {
            id: spectrum
            anchors.verticalCenter: parent.verticalCenter
            visible: Players.playing
        }
    }
}
