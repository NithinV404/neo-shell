import Quickshell
import QtQuick
import qs.Common
import qs.Services

PanelWindow {
    id: root

    property real menuX: 0
    property real menuY: 0
    property alias posX: root.menuX
    property alias posY: root.menuY
    property bool visible: false
    property bool isVisible: false

    signal menuClosed

    function openAt(x, y) {
        root.menuX = x - panelContainer.width / 2;
        root.menuY = y;
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        root.visible = false;
    }

    color: "transparent"

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
            const p = mapToItem(panelContainer, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= panelContainer.width && p.y >= 0 && p.y <= panelContainer.height);
            if (!inside) {
                root.close();
            }
        }
    }

    Item {
        id: panelContainer
        x: Utils.clampScreenX(root.menuX, width, 5)
        y: Utils.clampScreenY(root.menuY, height, 20)
        height: contentRect.height
        width: contentRect.width
        clip: true
        state: root.visible ? "open" : "closed"
        transformOrigin: Item.Top

        states: [
            State {
                name: "closed"
                PropertyChanges {
                    target: panelContainer
                    opacity: 0
                    scale: 0.9
                }
            },
            State {
                name: "open"
                PropertyChanges {
                    target: panelContainer
                    opacity: 1
                    scale: 1
                }
            }
        ]

        transitions: [
            Transition {
                from: "closed"
                to: "open"
                NumberAnimation {
                    target: panelContainer
                    properties: "opacity,scale"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            },
            Transition {
                from: "open"
                to: "closed"
                SequentialAnimation {
                    NumberAnimation {
                        target: panelContainer
                        properties: "opacity,scale"
                        duration: 220
                        easing.type: Easing.InCubic
                    }
                    ScriptAction {
                        script: {
                            root.visible = false;  // Hide window AFTER animation
                            root.menuClosed();
                        }
                    }
                }
            }
        ]
        Rectangle {
            id: contentRect
            color: Theme.getColor("surface")
            radius: 12
            implicitWidth: wallpaperGrid.implicitWidth + 40
            implicitHeight: wallpaperGrid.implicitHeight + 40
            WallpaperGrid {
                id: wallpaperGrid
                anchors.centerIn: parent
            }
        }
    }
}
