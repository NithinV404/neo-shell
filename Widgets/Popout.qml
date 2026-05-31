import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

PanelWindow {
    id: root

    // Public API (keep yours)
    property alias content: contentWindow.sourceComponent
    property alias contentItem: contentWindow.item

    property int animationDuration: 300
    property string vAlign: "top"
    property string hAlign: "left"
    property real panelWidth: contentWindow.item?.targetWidth ?? 0
    property real panelHeight: contentWindow.item?.targetHeight ?? 0
    property real panelX: 0
    property real panelY: 0
    property bool isVisible: false
    property bool shadowEnabled: false

    focusable: false

    visible: false

    signal menuClosed

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    function openAt(x, y) {
        if (root.visible) {
            close();
            return;
        }
        root.panelX = x;
        root.panelY = y;
        root.visible = true;
        Utils.timer(50, () => root.isVisible = true, root);
    }

    function close() {
        root.isVisible = false;

        Utils.timer(animationDuration, () => {
            root.visible = false;
            root.menuClosed();
        }, root);
    }

    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: {
        if (WlrLayershell != null) {
            WlrLayershell.layer = WlrLayer.Overlay;
            WlrLayershell.namespace = "neoshell:panel";
        }
    }

    MouseArea {
        id: outsideDismissArea
        anchors.fill: parent
        enabled: root.visible
        propagateComposedEvents: false
        onClicked: {
            root.close();
        }
    }

    Item {
        id: contentContainer
        x: {
            switch (root.hAlign) {
            case "center":
                return Utils.clampScreenX(root.panelX - (width / 2), width, 1, root.screen);
            case "left":
                return Utils.clampScreenX(root.panelX - width, width, 1, root.screen);
            case "right":
            default:
                return Utils.clampScreenX(root.panelX, width, 1, root.screen);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
        }

        y: (root.vAlign === "bottom") ? (root.panelY - height) : root.panelY

        width: root.panelWidth
        height: root.panelHeight

        Loader {
            id: contentWindow
            anchors.bottom: root.vAlign == "bottom" ? parent.bottom : undefined
            anchors.right: root.hAlign == "right" ? parent.right : undefined
            anchors.left: root.hAlign == "left" ? parent.left : undefined
            active: root.visible
        }
    }
}
