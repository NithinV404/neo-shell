pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import "../Helpers/fzf.js" as Fzf

Singleton {
    id: root

    signal applicationsUpdated

    readonly property ListModel applications: ListModel {
        id: appModel
    }

    property var _appList: []
    property var _fzfFinder: null

    function init() {
    }

    function _getApplications() {
        let apps = DesktopEntries.applications.values.filter(app => !app.noDisplay && !app.runInTerminal).sort((a, b) => a.name.localeCompare(b.name));
        Utils.diffListModel(apps, applications);
        applicationsUpdated();
        return;
    }

    // Get icon path for an app
    function getIconPath(app) {
        if (!app.icon)
            return "";
        return Quickshell.iconPath(app.icon, true);
    }

    function launchApp(item) {
        let app = _appList.find(e => item.id === e.id);
        if (app) {
            app.execute();
        }
    }

    function _fuzzyLoader() {
        _appList = Array.from(DesktopEntries.applications.values.filter(app => !app.noDisplay && !app.runInTerminal).sort((a, b) => a.name.localeCompare(b.name)));
        _fzfFinder = new Fzf.Finder(_appList, {
            // You can join multiple fields so Fzf searches name, comment AND keywords simultaneously!
            selector: a => `${a.name || ""} ${a.genericName || ""} ${a.comment || ""} ${(a.keywords || []).join(" ")}`,
            casing: "case-insensitive",
            fuzzy: "v1"
        });
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            Qt.callLater(() => {
                _getApplications();
                _fuzzyLoader();
            });
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            _getApplications();
            _fuzzyLoader();
        });
    }

    function searchApplications(query) {
        if (!query || query.trim() === "")
            return _getApplications();
        var result = Utils.heuristicSearch(_appList, query);
        if (result.length === 0) {
            try {
                if (_fzfFinder) {
                    const fuzzyResults = _fzfFinder.find(query);

                    if (fuzzyResults.length > 0) {
                        result = fuzzyResults.map(r => r.item);
                        Utils.diffListModel(result, applications);
                        applicationsUpdated();
                        return;
                    }
                }
            } catch (e) {
                console.error("FZF Search Error: ", e);
            }
        } else {
            applicationsUpdated();
            return Utils.diffListModel(result, applications);
        }
        applicationsUpdated();
        return applications.clear();
    }

    function getCategoriesForApp(app) {
        if (!app?.categories)
            return [];

        const categoryMap = {
            "AudioVideo": "Media",
            "Audio": "Media",
            "Video": "Media",
            "Development": "Development",
            "TextEditor": "Development",
            "IDE": "Development",
            "Education": "Education",
            "Game": "Games",
            "Graphics": "Graphics",
            "Photography": "Graphics",
            "Network": "Internet",
            "WebBrowser": "Internet",
            "Email": "Internet",
            "Office": "Office",
            "WordProcessor": "Office",
            "Spreadsheet": "Office",
            "Presentation": "Office",
            "Science": "Science",
            "Settings": "Settings",
            "System": "System",
            "Utility": "Utilities",
            "Accessories": "Utilities",
            "FileManager": "Utilities",
            "TerminalEmulator": "Utilities"
        };

        const mappedCategories = new Set();

        for (const cat of app.categories) {
            if (categoryMap[cat])
                mappedCategories.add(categoryMap[cat]);
        }

        return Array.from(mappedCategories);
    }

    property var categoryIcons: ({
            "All": "apps",
            "Media": "music_video",
            "Development": "code",
            "Games": "sports_esports",
            "Graphics": "photo_library",
            "Internet": "web",
            "Office": "content_paste",
            "Settings": "settings",
            "System": "host",
            "Utilities": "build"
        })

    function getCategoryIcon(category) {
        return categoryIcons[category] || "folder";
    }

    function getAllCategories() {
        const categories = new Set(["All"]);

        for (const app of applications) {
            const appCategories = getCategoriesForApp(app);
            appCategories.forEach(cat => categories.add(cat));
        }

        return Array.from(categories).sort();
    }

    function getAppsInCategory(category) {
        if (category === "All") {
            return applications;
        }

        return applications.filter(app => {
            const appCategories = getCategoriesForApp(app);
            return appCategories.includes(category);
        });
    }
}
