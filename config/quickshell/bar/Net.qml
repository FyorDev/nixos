pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    property string local: ""
    property string device: ""
    property string publicAddress: ""
    property bool showPublic: false
    property double fetched: 0

    readonly property var link: Networking.devices.values.find(d => d.name === device) ?? null
    readonly property bool wired: link !== null && link.type === DeviceType.Wired
    readonly property bool wifi: link !== null && link.type === DeviceType.Wifi
    readonly property var network: wifi ? (link.networks.values.find(n => n.connected) ?? null) : null
    readonly property real strength: network?.signalStrength ?? 0

    function refresh() {
        route.running = true;
        if (showPublic && Date.now() - fetched > 300000)
            lookup.running = true;
    }

    onShowPublicChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: route
        command: [Settings.ip, "-4", "route", "get", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.local = (text.match(/ src (\d+\.\d+\.\d+\.\d+)/) ?? [])[1] ?? "";
                root.device = (text.match(/ dev (\S+)/) ?? [])[1] ?? "";
            }
        }
    }

    Process {
        id: lookup
        command: [Settings.curl, "-fsS", "--max-time", "3", "https://api.ipify.org"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    root.publicAddress = text.trim();
                    root.fetched = Date.now();
                }
            }
        }
    }
}
