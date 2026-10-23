import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    property string message: ""
    property bool failed: false
    property bool busy: false
    property var users: [Settings.user]
    property int current: 0
    readonly property string user: users[current]

    signal submitted(string password)

    function clear() {
        field.text = "";
        field.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: Settings.base
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Settings.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        visible: Settings.wallpaper !== ""
        blurEnabled: true
        blur: 1.0
        blurMax: 64
    }

    Rectangle {
        anchors.fill: parent
        visible: Settings.wallpaper !== ""
        color: Settings.base
        opacity: 0.65
    }

    FontMetrics {
        id: metrics
        font.family: Settings.font
        font.pixelSize: 15
    }

    Column {
        id: boxes

        readonly property real line: width / 2 - 14 * metrics.averageCharacterWidth

        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: metrics.height

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: boxes.spacing
        }

        Fastfetch {
            x: boxes.line - textX
        }

        Tree {
            id: login
            x: boxes.line
            rows: [[key("", 0xF0004, "ID"), root.users.map((user, i) => Markup.paint(i === root.current ? "peach" : "overlay0", Markup.plain(user))).join("&nbsp;&nbsp;")]]

            Row {
                Line {
                    id: prompt
                    text: login.line(login.key("\u251c", 0xF0306, ""), "")
                }

                TextField {
                    id: field
                    width: 320
                    height: prompt.implicitHeight
                    padding: 0
                    topInset: 0
                    bottomInset: 0
                    echoMode: TextInput.Password
                    passwordCharacter: "*"
                    placeholderText: "password"
                    placeholderTextColor: Settings.overlay0
                    enabled: !root.busy
                    focus: true
                    color: root.failed ? Settings.red : Settings.subtext0
                    font.family: Settings.font
                    font.pixelSize: 15
                    // JetBrains Mono joins "***" into a ligature, which shifts the asterisks while typing
                    font.features: { "liga": 0, "calt": 0 }
                    background: null
                    cursorDelegate: Rectangle {
                        width: 9
                        color: Settings.mauve
                        visible: field.cursorVisible
                    }
                    onAccepted: if (text !== "")
                        root.submitted(text)
                    Keys.onUpPressed: root.current = (root.current + root.users.length - 1) % root.users.length
                    Keys.onDownPressed: root.current = (root.current + 1) % root.users.length
                    Component.onCompleted: forceActiveFocus()
                }
            }

            Line {
                visible: root.message !== ""
                text: login.line(login.key("\u251c", root.failed ? 0xF0028 : 0xF0150, ""), Markup.paint(root.failed ? "red" : "subtext0", Markup.plain(root.message)))
            }
        }
    }

    Media {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 48
    }

    Weather {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 48
    }
}
