pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root
    property var colors: ({})
    property bool darkMode: Settings.darkMode
    property string wallpaperPath: ""

    property QtObject internal: QtObject {
        property FileView watcher: FileView {
            id: fileFile

            path: Paths.home + "/.config/quickshell/quickshell.json"

            // Note: In QuickShell, text is a FUNCTION. You must call it.
            onTextChanged: {
                var content = fileFile.text(); // <--- CALL IT LIKE THIS

                if (!content)
                    return;

                try {
                    // Trim to remove invisible newlines that break JSON.parse
                    var json = JSON.parse(content.trim());

                    // Bulk update
                    root.colors = json.colors || {};
                    root.wallpaperPath = json.image || "";
                } catch (e) {
                    console.warn("[ColorScheme] JSON Parse Error:", e);
                }
            }
        }
    }

    function getColor(key, fallback) {
        var safeFallback = (fallback !== undefined) ? fallback : "#00000000";

        if (!root.colors)
            return safeFallback;

        var modeData = root.colors[root.darkMode ? "dark" : "light"];
        if (!modeData)
            return safeFallback;

        var val = modeData[key];

        return (val !== undefined) ? Qt.color(val) : Qt.color(safeFallback);
    }
}
