pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import "../Common/fzf.js" as Fzf

Singleton {
    id: root

    property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay && !app.runInTerminal).sort((a, b) => a.name.localeCompare(b.name))

    // Get icon path for an app
    function getIconPath(app) {
        if (!app.icon)
            return "";
        return Quickshell.iconPath(app.icon, true);
    }

    property var _fzfFinder: null
    onApplicationsChanged: {
        _fzfFinder = new Fzf.Finder(applications, {
            // You can join multiple fields so Fzf searches name, comment AND keywords simultaneously!
            selector: a => `${a.name || ""} ${a.genericName || ""} ${a.comment || ""} ${(a.keywords || []).join(" ")}`,
            casing: "case-insensitive",
            fuzzy: "v1"
        });
    }

    function searchApplications(query) {
        if (!query || query.trim() === "")
            return applications;
        var result = Utils.heuristicSearch(applications, query);
        if (result.length === 0) {
            try {
                if (_fzfFinder) {
                    const fuzzyResults = _fzfFinder.find(query);

                    if (fuzzyResults.length > 0) {
                        return fuzzyResults.map(r => r.item);
                    }
                }
            } catch (e) {
                console.error("FZF Search Error: ", e);
            }
        } else {
            return result;
        }

        return [];
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
