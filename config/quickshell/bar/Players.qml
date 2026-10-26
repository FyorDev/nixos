pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    readonly property MprisPlayer player: list.find(p => p.isPlaying) ?? list[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
}
