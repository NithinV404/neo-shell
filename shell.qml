//@ pragma Env QT_MEDIA_BACKEND=ffmpeg
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Wayland
import qs.Modules.Bar
import qs.Modules
import qs.Modals
import qs.Common
import qs.Modules.Launcher
import qs.Services

// import Niri

ShellRoot {
    id: root
    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Top;
        }
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
        source: Settings.wallpaperImage != "" ? Settings.wallpaperImage : "file:///home/nithin/Pictures/Wallpapers/wallhaven-8gg3lo_3840x2160.png"
        // color: "#1a1a2e"  // fallback color
    }

    VolumeOSD {}
    Launcher {}
    PowerMenu {}

    // Bar on each screen
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
