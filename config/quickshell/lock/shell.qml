import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: shell

    property string password: ""
    property string message: ""
    property bool failed: false

    signal cleared

    PamContext {
        id: pam
        config: "quickshell-lock"
        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(shell.password);
                shell.password = "";
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false;
                Qt.quit();
                return;
            }
            shell.failed = true;
            shell.message = "Wrong password";
            shell.cleared();
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            color: Settings.base

            LoginScreen {
                id: screen
                anchors.fill: parent
                message: shell.message
                failed: shell.failed
                busy: pam.active
                onSubmitted: password => {
                    shell.password = password;
                    shell.failed = false;
                    shell.message = "Checking";
                    pam.start();
                }

                Connections {
                    target: shell
                    function onCleared() {
                        screen.clear();
                    }
                }
            }
        }
    }
}
