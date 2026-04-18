pragma Singleton
import QtQuick
import QtCore
import Quickshell

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

    function heuristicSearch(items, query) {
        if (!query || query.length === 0)
            return items;
        if (items.length === 0)
            return [];

        const queryLower = query.toLowerCase().trim();
        const scoredApps = [];

        for (const app of items) {
            const name = (app.name || "").toLowerCase();
            const genericName = (app.genericName || "").toLowerCase();
            const comment = (app.comment || "").toLowerCase();
            const keywords = app.keywords ? app.keywords.map(k => k.toLowerCase()) : [];

            let score = 0;
            let matched = false;

            const nameWords = name.trim().split(/\s+/).filter(w => w.length > 0);
            const containsAsWord = nameWords.includes(queryLower);
            const startsWithAsWord = nameWords.some(word => word.startsWith(queryLower));

            if (name === queryLower) {
                score = 10000;
                matched = true;
            } else if (containsAsWord) {
                score = 9500 + (100 - Math.min(name.length, 100));
                matched = true;
            } else if (name.startsWith(queryLower)) {
                score = 9000 + (100 - Math.min(name.length, 100));
                matched = true;
            } else if (startsWithAsWord) {
                score = 8500 + (100 - Math.min(name.length, 100));
                matched = true;
            } else if (name.includes(queryLower)) {
                score = 8000 + (100 - Math.min(name.length, 100));
                matched = true;
            } else if (keywords.length > 0) {
                for (const keyword of keywords) {
                    if (keyword === queryLower) {
                        score = 6000;
                        matched = true;
                        break;
                    } else if (keyword.startsWith(queryLower)) {
                        score = 5500;
                        matched = true;
                        break;
                    } else if (keyword.includes(queryLower)) {
                        score = 5000;
                        matched = true;
                        break;
                    }
                }
            }
            if (!matched && genericName.includes(queryLower)) {
                score = 4000;
                matched = true;
            } else if (!matched && comment.includes(queryLower)) {
                score = 3000;
                matched = true;
            }
            if (matched) {
                scoredApps.push({
                    "app": app,
                    "score": score
                });
            }
        }
        scoredApps.sort((a, b) => b.score - a.score);
        return scoredApps.slice(0, 50).map(item => item.app);
    }

    function timer(interval, callback, root): QtObject {
        const t = Qt.createQmlObject(`import QtQuick
        Timer
        { id: timer
          interval: ${interval}
          running: true
        }`, root);
        t.triggered.connect(() => {
            callback();
            t.destroy();
        });
        return t;
    }
}
