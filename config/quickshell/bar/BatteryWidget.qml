import QtQuick
import Quickshell.Services.UPower

Button {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property real percent: device.percentage <= 1 ? device.percentage * 100 : device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged
    readonly property color tone: charging ? Settings.green : percent <= 10 ? Settings.red : percent <= 25 ? Settings.yellow : Settings.teal
    readonly property real seconds: charging ? device.timeToFull : device.timeToEmpty
    readonly property string status: {
        if (device.state === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        const time = duration(seconds);
        if (charging)
            return "Charging" + (time ? ", " + time + " until full" : "");
        return "On battery" + (time ? ", " + time + " left" : "");
    }

    function duration(total) {
        if (total <= 0)
            return "";
        const minutes = Math.round(total / 60);
        return Math.floor(minutes / 60) + "h " + String(minutes % 60).padStart(2, "0") + "m";
    }

    visible: device.isPresent
    tip: [status, Math.abs(device.changeRate) >= 0.1 ? Math.abs(device.changeRate).toFixed(1) + " W" + (charging ? " in" : " out") : "", device.energy.toFixed(1) + " / " + device.energyCapacity.toFixed(1) + " Wh", device.healthSupported ? "Health " + Math.round(device.healthPercentage) + "%" : ""].filter(line => line !== "").join("\n")

    Glyph {
        code: root.charging ? 0xF0E7 : [0xF244, 0xF243, 0xF242, 0xF241, 0xF240][Math.min(4, Math.floor(root.percent / 20))]
        color: root.tone
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.percent) + "%"
        color: root.tone
        font.family: Settings.font
        font.pixelSize: 13
    }
}
