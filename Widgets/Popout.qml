import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

QtObject {
    id: root

    // Public API (keep yours)
    property alias content: contentWindow.sourceComponent
    property alias contentItem: contentWindow.item

    property int animationDuration: 300
    property real panelWidth: contentWindow.item?.targetWidth ?? 0
    property real panelHeight: contentWindow.item?.targetHeight ?? 0
    property string vAlign: "top"
    property string hAlign: "left"
    property real panelX: 0
    property real panelY: 0
    property bool isVisible: false

    signal menuClosed

    function openAt(x, y) {
        if (menuWindow.visible) {
            close();
            return;
        }

        root.panelX = x;
        root.panelY = y;

        // Map both surfaces. We map the menu first so its content can start loading,
        // then the catcher goes visible (it has a hole, so it won't eat menu input).
        menuWindow.visible = true;
        clickCatcher.visible = true;

        Utils.timer(50, () => root.isVisible = true, menuWindow);
    }

    function close() {
        root.isVisible = false;

        Utils.timer(animationDuration, () => {
            clickCatcher.visible = false;
            menuWindow.visible = false;
            root.menuClosed();
        }, menuWindow);
    }

    // --------------------------
    // Window B: the actual menu
    // --------------------------
    PanelWindow {
        id: menuWindow
        visible: false
        focusable: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        Component.onCompleted: {
            if (WlrLayershell != null) {
                WlrLayershell.layer = WlrLayer.Overlay;
                WlrLayershell.namespace = "neoshell:panel";
            }
        }

        // Use client-shaped blur (ext-background-effect-v1).
        // Setting blurRegion to null removes blur. <!--citation:3-->
        BackgroundEffect.blurRegion: Region {
            item: contentContainer
            radius: Settings.radius
        }

        // Optional but recommended:
        // Only the menu rectangle receives pointer input; outside clicks pass through
        // to the click-catcher sibling (below).
        mask: Region {
            item: contentContainer
            radius: Settings.radius
        }

        Item {
            id: contentContainer

            x: {
                switch (root.hAlign) {
                case "center":
                    return Utils.clampScreenX(root.panelX - (width / 2), width, 1, menuWindow.screen);
                case "left":
                    return Utils.clampScreenX(root.panelX - width, width, 1, menuWindow.screen);
                case "right":
                default:
                    return Utils.clampScreenX(root.panelX, width, 1, menuWindow.screen);
                }
            }

            y: (root.vAlign === "bottom") ? (root.panelY - height) : root.panelY

            width: root.panelWidth
            height: root.panelHeight
            opacity: root.isVisible ? 1 : 0

            Behavior on height {
                NumberAnimation {
                    from: 1
                    duration: root.animationDuration
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: contentWindow
                active: menuWindow.visible
            }
        }
    }

    // -----------------------------------------
    // Window A: fullscreen outside-click catcher
    // -----------------------------------------
    PanelWindow {
        id: clickCatcher
        visible: false
        focusable: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        Component.onCompleted: {
            if (WlrLayershell != null) {
                WlrLayershell.layer = WlrLayer.Overlay;
                WlrLayershell.namespace = "neoshell:panel-catcher";
            }
        }

        // "Hole punch": everything is clickable EXCEPT the menu rectangle.
        // Using Intersection.Xor inverts the mask so clicks inside the region
        // pass through to the window behind. <!--citation:1-->
        mask: Region {
            item: hole
            radius: Settings.radius
            intersection: Intersection.Xor
        }

        // This item mirrors the menu rectangle in the SAME coordinate space
        // (both windows are fullscreen), so it lines up.
        Item {
            id: hole
            x: menuWindow.visible ? menuWindow.contentItem.mapFromItem(menuWindow.contentItem, 0, 0).x : contentContainer.x
            y: contentContainer.y
            width: Math.max(contentContainer.width, 1)
            height: Math.max(contentContainer.height, 1)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.close()
        }
    }
}
