//@ pragma Env QT_MEDIA_BACKEND=ffmpeg
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma UseQApplication

import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.Modules.Bar
import qs.Modules.Launcher
import qs.Modules
import qs.Modals
import qs.Common
import qs.Services

// import Niri

ShellRoot {
    id: root
    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Top;
        }
        IPCService.init();
    }

    // Process {
    //     id: pkillProcess
    // }
    // Process {
    //     id: setWallpaper
    // }
    // Process {
    //     id: generateMutagenColors
    // }

    // Niri {
    //     id: niri
    //     Component.onCompleted: connect()

    //     onConnected: console.log("Connected to niri")
    //     onErrorOccurred: function (error) {
    //         console.error("Error:", error);
    //     }
    // }
    Wallpaper {
        source: Settings.wallpaperImage
        // color: "#1a1a2e"  // fallback color
    }

    OSD {}
    PowerMenu {}
    Launcher {}

    // Bar on each screen
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
