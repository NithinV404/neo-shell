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
    property bool visible: false
    property bool isVisible: false

    signal menuClosed

    function openAt(x, y) {
        root.menuX = x;
        root.menuY = y;
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        root.visible = false;
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
        implicitWidth: quickLayoutStack.trackedWidth + 40
        implicitHeight: quickLayoutStack.trackedHeight + 24
        clip: false
        state: root.visible ? "open" : "closed"
        transformOrigin: Item.Top

        DropShadow {
            anchors.fill: panelRect
            source: panelRect
            horizontalOffset: 0
            verticalOffset: 8
            radius: 18
            samples: 49
            color: Qt.rgba(0, 0, 0, 0.35)
            transparentBorder: true
        }

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
                id: openAnim
                from: "closed"
                to: "open"
                reversible: true
                SequentialAnimation {
                    ScriptAction {
                        script: {
                            if (!root.visible) {
                                root.isVisible = false;
                                root.menuClosed();
                            }
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity,scale"
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        ]

        Rectangle {
            id: panelRect
            anchors.fill: parent
            radius: Settings.radius
            color: Theme.surface
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        }

        StackLayout {
            id: quickLayoutStack
            currentIndex: 0
            clip: true
            property QtObject currentItem: children[currentIndex]
            property real trackedHeight: currentItem.implicitHeight
            property real trackedWidth: currentItem.implicitWidth
            width: trackedWidth
            height: trackedHeight
            anchors.margins: 12
            anchors.centerIn: parent

            Behavior on trackedHeight {
                enabled: root.isVisible
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }

            Behavior on trackedWidth {
                enabled: root.isVisible
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }

            ControlCenterPanel {
                id: controlCenterPanel
            }

            Loader {
                id: wifiPanelPanel
                asynchronous: true
                sourceComponent: NetworkPanel {
                    onGoBack: quickLayoutStack.currentIndex = 0
                    anchors.fill: parent
                }
            }

            Loader {
                id: bluetoothPanel
                asynchronous: true
                sourceComponent: BluetoothPanel {
                    bluetooth: BluetoothService
                    onGoBack: quickLayoutStack.currentIndex = 0
                    anchors.fill: parent
                }
            }

            Loader {
                id: audioPanel
                asynchronous: true
                sourceComponent: AudioPanel {
                    onGoBack: quickLayoutStack.currentIndex = 0
                    anchors.fill: parent
                }
            }
        }
    }
}
