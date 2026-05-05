import QtQuick
import Quickshell.Wayland
import Quickshell
import qs.Common

PanelWindow {
    id: root
    required property var screen
    property alias content: contentWindow.sourceComponent
    property int animationDuration: 300 
    property int panelX: 0
    property int panelY: 0
    property bool isVisible: false
    property bool shadowEnabled: false 
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
        Utils.timer(animationDuration, () => {
            root.visible = false;
            root.menuClosed();
        }, root);

    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "neoshell:blur" 
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    onIsVisibleChanged: 
    {
        if(isVisible)
        {
            Utils.timer(root.animationDuration, ()=> {
                root.shadowEnabled =  true 
            }, root )
        }
        else 
        {
            root.shadowEnabled = false
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            if (!root.contentItem) {
                root.close();
                return;
            }
            const p = mapToItem(contentWindow, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= contentWindow.item.width && p.y >= 0 && p.y <= contentWindow.item.height);
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
