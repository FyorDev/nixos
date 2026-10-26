import QtQuick

Button {
    id: root

    required property var screen

    active: Popups.name === "network" && Popups.screen === screen
    onClicked: Popups.toggle("network", screen, root)
    tip: Net.local === "" ? "Offline" : Net.wired ? "Wired" : Net.network ? Net.network.name + ", " + Math.round(Net.strength * 100) + "%" : "Connected"

    Glyph {
        code: Net.local === "" ? 0xF05AA : Net.wired ? 0xF0200 : [0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(3, Math.floor(Net.strength * 4))]
        color: Net.local === "" ? Settings.red : Settings.subtext0
    }
}
