import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Services
import qs.Common
import qs.Modules.Bar.Panels
import Quickshell.Wayland

PanelWindow {
    id: root

    // Use real for coords (they're numbers, not "var")
    required property var screen
    property real menuX: 0
    property real menuY: 0
    property alias posX: root.menuX
    property alias posY: root.menuY
    property bool isVisible: false
    visible: false

    signal menuClosed

    function openAt(x, y) {
        root.menuX = x;
        root.menuY = y;
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
            const p = mapToItem(quickLayoutStack, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= quickLayoutStack.width && p.y >= 0 && p.y <= quickLayoutStack.height);
            if (!inside) {
                root.close();
            }
        }
    }

    Item {
        id: panelContainer
        x: Utils.clampScreenX(root.menuX, width, 5, root.screen)
        y: Utils.clampScreenY(root.menuY, height, 0, root.screen)
        width: quickLayoutStack.itemWidth + 24
        height: root.isVisible ? quickLayoutStack.itemHeight + 24 : 0
        opacity: root.isVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            SequentialAnimation {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
                ScriptAction {
                    script: {
                        if (!root.isVisible) {
                            root.visible = false;
                            root.menuClosed();
                        }
                    }
                }
            }
        }

        Rectangle {
            id: panelRect
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            radius: Settings.radius
            color: Theme.surface
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 18
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.35)
                transparentBorder: true
            }
        }

        StackLayout {
            id: quickLayoutStack
            readonly property int itemHeight: {
                let currentItem = children[currentIndex];
                let h = currentItem.item ? currentItem.item.implicitHeight : currentItem.implicitHeight;
                return h > 0 ? h : 350;
            }
            readonly property int itemWidth: {
                let currentItem = children[currentIndex];
                let w = currentItem.item ? currentItem.item.implicitWidth : currentItem.implicitWidth;
                return w > 0 ? w : 350;
            }
            height: itemHeight
            width: itemWidth
            currentIndex: 0
            clip: true
            anchors.fill: parent
            anchors.margins: 12
            visible: root.visible

            ControlCenterPanel {
                id: controlCenterPanel
            }

            Loader {
                id: wifiPanelPanel
                sourceComponent: NetworkPanel {
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }

            Loader {
                id: bluetoothPanel
                sourceComponent: BluetoothPanel {
                    bluetooth: BluetoothService
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }

            Loader {
                id: audioPanel
                sourceComponent: AudioPanel {
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }
        }
    }
}
