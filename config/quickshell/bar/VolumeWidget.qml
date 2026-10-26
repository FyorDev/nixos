import QtQuick

Button {
    id: root

    required property var screen

    active: Popups.name === "volume" && Popups.screen === screen
    onClicked: event => {
        if (event.button === Qt.RightButton)
            Audio.toggleMute();
        else
            Popups.toggle("volume", screen, root);
    }
    onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.02 : -0.02))
    tip: Audio.sink ? Audio.name(Audio.sink) : "No output"

    Glyph {
        code: Audio.muted || Audio.volume === 0 ? 0xF026 : Audio.volume < 0.5 ? 0xF027 : 0xF028
        color: Audio.muted ? Settings.overlay0 : Settings.sapphire
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.muted ? "muted" : Math.round(Audio.volume * 100) + "%"
        color: Audio.muted ? Settings.overlay0 : Settings.sapphire
        font.family: Settings.font
        font.pixelSize: 13
    }
}
