pragma Singleton
import QtQuick
import QtCore
import Quickshell
import qs.Modules.Bar

QtObject {

    readonly property url config: `${StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0]}`
    readonly property url cache: `${StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]}/neoshell`
    readonly property url imagecache: `${cache}/imagecache`

    function clampScreenX(x, width, padding, screen) {
        var screenWidth = screen.width;
        var edge = x + width;
        return edge < screenWidth ? x : screenWidth - width - padding;
    }

    function clampScreenY(y, height, padding, screen) {
        var screenHeight = screen.height;
        var edge = y + height;
        return edge > screenHeight ? y - height - padding : y;
    }

    function getElevatedColor(baseColor, tintColor, level) {
        var opacity = 0;
        if (level === 1)
            opacity = 0.05;
        if (level === 2)
            opacity = 0.08;
        if (level === 3)
            opacity = 0.11;
        return Qt.tint(baseColor, Qt.rgba(tintColor.r, tintColor.g, tintColor.b, opacity));
    }

    function strip(path: url): string {
        return path.toString(path).replace("file://", "");
    }

    function stringify(path: url): string {
        return path.toString().replace(/%20/g, " ").replace(/^file:\/\//, "");
    }

    function mkdir(path: url): void {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }

    function resolvePath(path) {
        if (!path)
            return "";

        let resolved = path;

        // 1. Handle Tilde (~)
        if (resolved.startsWith("~")) {
            const home = Quickshell.env("HOME") || "/home/" + Quickshell.env("USER");
            resolved = resolved.replace("~", home);
        }

        // 2. Handle Environment Variables (e.g., $HOME/Wallpapers or ${HOME}/Wallpapers)
        resolved = resolved.replace(/\$(\w+)/g, (_, key) => Quickshell.env(key) || "");
        resolved = resolved.replace(/\${(\w+)}/g, (_, key) => Quickshell.env(key) || "");

        // 3. Clean up double slashes (except the protocol file://)
        // This turns "home/user//Pictures" into "home/user/Pictures"
        resolved = resolved.replace(/([^:])\/\//g, "$1/");

        return resolved;
    }
}
