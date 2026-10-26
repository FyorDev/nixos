import QtQuick

Button {
    id: root

    required property var screen

    active: Popups.name === "capture" && Popups.screen === screen
    tip: Capture.recording ? "Recording, click to stop" : Capture.mirroring ? "Mirroring a display" : "Screenshots, recording and mirroring"
    onClicked: event => {
        // while recording a left click stops it, the menu stays on the other buttons
        if (Capture.recording && event.button === Qt.LeftButton)
            Capture.stopRecording();
        else
            Popups.toggle("capture", screen, root);
    }

    Glyph {
        code: Capture.recording ? 0xF111 : Capture.mirroring ? 0xF26C : 0xF030
        color: Capture.recording ? Settings.red : Settings.mauve
    }
}
