pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    property bool isHyprland: false
    property bool isNiri: false
    property string compositor: "unknown"

    readonly property string hyprlandSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string niriSocket: Quickshell.env("NIRI_SOCKET")
    readonly property bool useHyprlandFocusGrab: isHyprland && Quickshell.env("DMS_HYPRLAND_EXCLUSIVE_FOCUS") !== "1"

    property bool useNiriSorting: isNiri && NiriService

    property var sortedToplevels: {
        if (!ToplevelManager.toplevels || !ToplevelManager.toplevels.values) {
            return [];
        }

        if (useNiriSorting) {
            return NiriService.sortToplevels(ToplevelManager.toplevels.values);
        }

        if (isHyprland) {
            const hyprlandToplevels = Array.from(Hyprland.toplevels.values);

            const sortedHyprland = hyprlandToplevels.sort((a, b) => {
                if (a.monitor && b.monitor) {
                    const monitorCompare = a.monitor.name.localeCompare(b.monitor.name);
                    if (monitorCompare !== 0) {
                        return monitorCompare;
                    }
                }

                if (a.workspace && b.workspace) {
                    const workspaceCompare = a.workspace.id - b.workspace.id;
                    if (workspaceCompare !== 0) {
                        return workspaceCompare;
                    }
                }

                if (a.lastIpcObject && b.lastIpcObject && a.lastIpcObject.at && b.lastIpcObject.at) {
                    const aX = a.lastIpcObject.at[0];
                    const bX = b.lastIpcObject.at[0];
                    const aY = a.lastIpcObject.at[1];
                    const bY = b.lastIpcObject.at[1];

                    const xCompare = aX - bX;
                    if (Math.abs(xCompare) > 10) {
                        return xCompare;
                    }
                    return aY - bY;
                }

                if (a.lastIpcObject && !b.lastIpcObject) {
                    return -1;
                }
                if (!a.lastIpcObject && b.lastIpcObject) {
                    return 1;
                }

                if (a.title && b.title) {
                    return a.title.localeCompare(b.title);
                }

                return 0;
            });

            return sortedHyprland.map(hyprToplevel => hyprToplevel.wayland).filter(wayland => wayland !== null);
        }

        return ToplevelManager.toplevels.values;
    }

    Component.onCompleted: {
        detectCompositor();
    }

    function filterCurrentWorkspace(toplevels, screen) {
        if (useNiriSorting) {
            return NiriService.filterCurrentWorkspace(toplevels, screen);
        }
        if (isHyprland) {
            return filterHyprlandCurrentWorkspace(toplevels, screen);
        }
        return toplevels;
    }

    function filterHyprlandCurrentWorkspace(toplevels, screenName) {
        if (!toplevels || toplevels.length === 0 || !Hyprland.toplevels) {
            return toplevels;
        }

        let currentWorkspaceId = null;
        const hyprlandToplevels = Array.from(Hyprland.toplevels.values);

        for (const hyprToplevel of hyprlandToplevels) {
            if (hyprToplevel.monitor && hyprToplevel.monitor.name === screenName && hyprToplevel.workspace) {
                if (hyprToplevel.activated) {
                    currentWorkspaceId = hyprToplevel.workspace.id;
                    break;
                }
                if (currentWorkspaceId === null) {
                    currentWorkspaceId = hyprToplevel.workspace.id;
                }
            }
        }

        if (currentWorkspaceId === null && Hyprland.workspaces) {
            const workspaces = Array.from(Hyprland.workspaces.values);
            for (const workspace of workspaces) {
                if (workspace.monitor && workspace.monitor === screenName) {
                    if (Hyprland.focusedWorkspace && workspace.id === Hyprland.focusedWorkspace.id) {
                        currentWorkspaceId = workspace.id;
                        break;
                    }
                    if (currentWorkspaceId === null) {
                        currentWorkspaceId = workspace.id;
                    }
                }
            }
        }

        if (currentWorkspaceId === null) {
            return toplevels;
        }

        return toplevels.filter(toplevel => {
            for (const hyprToplevel of hyprlandToplevels) {
                if (hyprToplevel.wayland === toplevel) {
                    return hyprToplevel.workspace && hyprToplevel.workspace.id === currentWorkspaceId;
                }
            }
            return false;
        });
    }

    function detectCompositor() {
        if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true;
            isNiri = false;
            compositor = "hyprland";
            return;
        }

        if (niriSocket && niriSocket.length > 0) {
            niriSocketCheck.running = true;
        } else {
            isHyprland = false;
            isNiri = false;
            compositor = "unknown";
        }
    }

    function powerOffMonitors() {
        if (isNiri) {
            return NiriService.powerOffMonitors();
        }
        if (isHyprland) {
            return Hyprland.dispatch("dpms off");
        }
    }

    function powerOnMonitors() {
        if (isNiri) {
            return NiriService.powerOnMonitors();
        }
        if (isHyprland) {
            return Hyprland.dispatch("dpms on");
        }
    }

    function applyBlurSettings(blurSize, blurPasses) {
        if (!isHyprland) {
            return false;
        }

        try {
            if (blurSize === 0) {
                hyprKeyword1.command = ["hyprctl", "keyword", "blur:enabled", "false"];
                hyprKeyword1.startDetached();
            } else {
                hyprKeyword1.command = ["hyprctl", "keyword", "blur:enabled", "true"];
                hyprKeyword1.startDetached();
                hyprKeyword2.command = ["hyprctl", "keyword", "blur:size", String(blurSize)];
                hyprKeyword2.startDetached();
                hyprKeyword3.command = ["hyprctl", "keyword", "blur:passes", String(blurPasses)];
                hyprKeyword3.startDetached();
                hyprKeyword4.command = ["hyprctl", "keyword", "blur:new_optimizations", "true"];
                hyprKeyword4.startDetached();
                hyprKeyword5.command = ["hyprctl", "keyword", "blur:ignore_opacity", "false"];
                hyprKeyword5.startDetached();
                hyprKeyword6.command = ["hyprctl", "keyword", "blur:xray", "false"];
                hyprKeyword6.startDetached();
                hyprKeyword7.command = ["hyprctl", "keyword", "blur:special", "false"];
                hyprKeyword7.startDetached();
            }
            return true;
        } catch (error) {
            return false;
        }
    }

    function updateBlurConfigSize(size) {
        if (!isHyprland) {
            return false;
        }

        try {
            if (size === 0) {
                var cmd = "sed -i 's/enabled = true/enabled = false/' /home/matt/.config/hypr/hyprland/decoration.conf";
                blurConfigUpdateProcess1.command = ["sh", "-c", cmd];
                blurConfigUpdateProcess1.startDetached();
            } else {
                var cmd = "sed -i 's/enabled = false/enabled = true/; s/size = [0-9]\\+/size = " + size + "/' /home/matt/.config/hypr/hyprland/decoration.conf";
                blurConfigUpdateProcess1.command = ["sh", "-c", cmd];
                blurConfigUpdateProcess1.startDetached();

                // Also ensure other blur settings are set for comprehensive control
                var cmd2 = "sed -i 's/new_optimizations = false/new_optimizations = true/; s/ignore_opacity = true/ignore_opacity = false/; s/xray = true/xray = false/; s/special = true/special = false/' /home/matt/.config/hypr/hyprland/decoration.conf";
                blurConfigUpdateProcess2.command = ["sh", "-c", cmd2];
                blurConfigUpdateProcess2.startDetached();
            }
            return true;
        } catch (error) {
            return false;
        }
    }

    function updateBlurConfigPasses(passes) {
        if (!isHyprland) {
            return false;
        }

        try {
            var cmd = "sed -i 's/passes = [0-9]\\+/passes = " + passes + "/' /home/matt/.config/hypr/hyprland/decoration.conf";
            blurConfigUpdateProcess2.command = ["sh", "-c", cmd];
            blurConfigUpdateProcess2.startDetached();
            return true;
        } catch (error) {
            return false;
        }
    }

    function applyBorderSize(size) {
        if (!isHyprland) {
            return false;
        }

        try {
            var cmd = "sed -i 's/border_size = [0-9]\\+/border_size = " + size + "/' /home/matt/.config/hypr/hyprland/colors.conf && hyprctl reload";
            borderUpdateProcess.command = ["sh", "-c", cmd];
            borderUpdateProcess.startDetached();
            return true;
        } catch (error) {
            return false;
        }
    }

    function applyBorderColors(hueShift, alpha) {
        if (!isHyprland) {
            return false;
        }

        try {
            // Get primary color from theme
            var primaryColor = typeof Theme !== 'undefined' ? Theme.primary : Qt.rgba(0.26, 0.65, 0.96, 1.0);

            // Convert RGB to HSL
            var r = primaryColor.r;
            var g = primaryColor.g;
            var b = primaryColor.b;
            var max = Math.max(r, Math.max(g, b));
            var min = Math.min(r, Math.min(g, b));
            var h, s, l = (max + min) / 2;
            var d = max - min;

            if (d !== 0) {
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                if (max === r) {
                    h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
                } else if (max === g) {
                    h = ((b - r) / d + 2) / 6;
                } else {
                    h = ((r - g) / d + 4) / 6;
                }
            } else {
                h = s = 0;
            }

            // Apply hue shift (convert degrees to 0-1 range)
            h = (h + hueShift / 360.0) % 1.0;
            if (h < 0)
                h += 1.0;

            // Convert HSL back to RGB
            var hue2rgb = function (p, q, t) {
                if (t < 0)
                    t += 1;
                if (t > 1)
                    t -= 1;
                if (t < 1 / 6)
                    return p + (q - p) * 6 * t;
                if (t < 1 / 2)
                    return q;
                if (t < 2 / 3)
                    return p + (q - p) * (2 / 3 - t) * 6;
                return p;
            };

            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1 / 3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1 / 3);

            // Blend with black background to simulate alpha
            var bgR = 0.0;
            var bgG = 0.0;
            var bgB = 0.0;
            r = r * alpha + bgR * (1 - alpha);
            g = g * alpha + bgG * (1 - alpha);
            b = b * alpha + bgB * (1 - alpha);

            // Convert to hex
            var toHex = function (x) {
                var v = Math.round(Math.max(0, Math.min(255, x * 255)));
                return v.toString(16).padStart(2, '0');
            };
            var hexColor = toHex(r) + toHex(g) + toHex(b);

            // Update config file
            var cmd = "sed -i 's/col\\.active_border = rgb([0-9a-fA-F]\\{6\\})/col.active_border = rgb(" + hexColor + ")/' /home/matt/.config/hypr/hyprland/colors.conf && hyprctl reload";
            borderColorUpdateProcess.command = ["sh", "-c", cmd];
            borderColorUpdateProcess.startDetached();
            return true;
        } catch (error) {
            return false;
        }
    }

    function reloadHyprlandConfig() {
        if (!isHyprland) {
            return false;
        }

        try {
            Hyprland.dispatch("reload");
            return true;
        } catch (error) {
            return false;
        }
    }

    Process {
        id: niriSocketCheck
        command: ["test", "-S", root.niriSocket]

        onExited: exitCode => {
            if (exitCode === 0) {
                root.isNiri = true;
                root.isHyprland = false;
                root.compositor = "niri";
            } else {
                root.isHyprland = false;
                root.isNiri = true;
                root.compositor = "niri";
            }
        }
    }

    Process {
        id: hyprKeyword1
        command: ["true"]
    }
    Process {
        id: hyprKeyword2
        command: ["true"]
    }
    Process {
        id: hyprKeyword3
        command: ["true"]
    }
    Process {
        id: hyprKeyword4
        command: ["true"]
    }
    Process {
        id: hyprKeyword5
        command: ["true"]
    }
    Process {
        id: hyprKeyword6
        command: ["true"]
    }
    Process {
        id: hyprKeyword7
        command: ["true"]
    }
    Process {
        id: borderUpdateProcess
        command: ["true"]
    }
    Process {
        id: borderColorUpdateProcess
        command: ["true"]
    }
    Process {
        id: blurConfigUpdateProcess1
        command: ["true"]
    }
    Process {
        id: blurConfigUpdateProcess2
        command: ["true"]
    }
}
