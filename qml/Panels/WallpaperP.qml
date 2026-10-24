import QtQuick
import QtQuick.Window
import Shell.Services
import Shell.Widgets
import Shell

PanelWindow {
    id: root
    visible: false
    layer: PanelWindow.Overlay
    anchors: PanelWindow.AnchorTop | PanelWindow.AnchorRight | PanelWindow.AnchorBottom | PanelWindow.AnchorLeft
    exclusionZone: 32
    keyboardInteractivity: PanelWindow.None
    color: "transparent"

    property bool isVisible: false

    // Single reusable timer instance for the hide delay
    Timer {
        id: hideTimer
        interval: 200
        repeat: false
        onTriggered: root.visible = false
    }

    function open() {
        if (root.visible) return;
        hideTimer.stop();
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        if (!root.visible) return;
        root.isVisible = false;
        hideTimer.restart();
    }

    function toggle() {
        root.visible ? close() : open();
        return -1;
    }

    Rectangle {
        width: 200
        height: root.isVisible ? 100 : 0
        radius: 12
        color: ThemeManager.surface

        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }
}
