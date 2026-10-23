import QtQuick
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
    id: shell

    property string password: ""
    property string message: ""
    property bool failed: false
    property bool busy: false

    function fail(text) {
        shell.failed = true;
        shell.busy = false;
        shell.message = text;
        shell.password = "";
        screen.clear();
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(shell.password);
                shell.password = "";
            } else if (error) {
                shell.message = message;
            }
        }

        function onAuthFailure(message) {
            Greetd.cancelSession();
            shell.fail("Wrong password");
        }

        function onReadyToLaunch() {
            shell.message = "Starting niri";
            Greetd.launch(Settings.session);
        }

        function onError(error) {
            Greetd.cancelSession();
            shell.fail(error);
        }
    }

    FloatingWindow {
        color: Settings.base

        LoginScreen {
            id: screen
            anchors.fill: parent
            message: shell.message
            failed: shell.failed
            busy: shell.busy
            users: Settings.users
            onSubmitted: password => {
                shell.password = password;
                shell.failed = false;
                shell.busy = true;
                shell.message = "Checking";
                Greetd.createSession(screen.user);
            }
        }
    }
}
