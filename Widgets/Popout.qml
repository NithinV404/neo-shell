import QtQuick
import Quickshell.Wayland
import Quickshell
import qs.Common

PanelWindow {
    id: root

    // Use real for coords (they're numbers, not "var")
    property alias content: contentWindow.sourceComponent
    property int panelX: 0
    property int panelY: 0
    property bool isVisible: false
    visible: false

    signal menuClosed

    function openAt(x, y) {
        root.panelX = x;
        root.panelY = y;
        root.visible = true;
        Utils.timer(30, () => {
            root.isVisible = true;
        }, root);
    }

    function close() {
        root.isVisible = false;
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Click-outside-to-close
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            const p = mapToItem(contentWindow, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= contentWindow.width && p.y >= 0 && p.y <= contentWindow.height);
            if (!inside) {
                root.close();
            }
        }
    }

    Loader {
        id: contentWindow
        active: root.visible
    }
}
