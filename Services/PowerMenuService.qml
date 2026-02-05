pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal toggleRequested
    signal openRequested
    signal closeRequested

    function toggle() {
        toggleRequested();
    }

    function open() {
        openRequested();
    }

    function close() {
        closeRequested();
    }

    IpcHandler {
        target: "wlogout"

        function toggleWlogoutMenu() {
            root.toggle();
        }

        function showWLogout() {
            root.open();
        }

        function hideWLogout() {
            root.close();
        }
    }
}
