pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.Services

Singleton {
    id: root

    function init() {
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            LauncherService.toggle();
        }

        function show() {
            LauncherService.open();
        }

        function hide() {
            LauncherService.close();
        }
    }

    IpcHandler {
        target: "wlogout"

        function toggle() {
            PowerMenuService.toggle();
        }

        function show() {
            PowerMenuService.open();
        }

        function hide() {
            PowerMenuService.close();
        }
    }

    IpcHandler {
        target: "media"

        function playPause() {
            MediaService.playPause();
        }

        function play() {
            MediaService.play();
        }

        function pause() {
            MediaService.pause();
        }

        function next() {
            MediaService.next();
        }

        function prev() {
            MediaService.previous();
        }
    }

    IpcHandler {
        target: "audio"

        function increaseVolume() {
            AudioService.increaseVolume();
        }

        function decreaseVolume() {
            AudioService.decreaseVolume();
        }

        function mute() {
            AudioService.setOutputMuted(!AudioService.muted);
        }

        function inputMute() {
            AudioService.setInputMuted(!AudioService.inputMuted);
        }
    }
}
