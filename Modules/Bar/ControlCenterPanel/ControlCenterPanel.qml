import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Widgets
import qs.Services
import qs.Common
import qs.Modules.Bar.ControlCenterPanel

Popout {
    id: root

    content: Item {
        id: panelContainer
        x: Utils.clampScreenX(root.panelX, width, 4, root.screen)
        y: Utils.clampScreenY(root.panelY, height, 0, root.screen)
        height: root.isVisible ? quickLayoutStack.itemHeight + 24 : 0
        width: quickLayoutStack.itemWidth + 24
        opacity: root.isVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
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
            layer.enabled: root.shadowEnabled
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
            property real itemWidth: children[currentIndex].implicitWidth
            property real itemHeight: children[currentIndex].implicitHeight
            property int previousIndex: 0
            currentIndex: 0
            clip: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            x: 12
            y: 12

            function switchTo(i) {
                previousIndex = currentIndex;
                swapAnimation.start();
                Utils.timer(120, () => {
                    currentIndex = i;
                }, quickLayoutStack);
            }

            SequentialAnimation {
                id: swapAnimation
                NumberAnimation {
                    target: quickLayoutStack
                    property: "opacity"
                    to: 0
                    duration: 120
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: quickLayoutStack
                    property: "opacity"
                    to: 1
                    duration: 150
                    easing.type: Easing.InQuad
                }
            }

            ControlCenter {
                id: controlPanel
                screen: root.screen
            }

            Network {
                onGoBack: quickLayoutStack.switchTo(0)
            }

            Bluetooth {
                bluetooth: BluetoothService
                onGoBack: quickLayoutStack.switchTo(0)
            }

            Audio {
                onGoBack: quickLayoutStack.switchTo(0)
            }
        }
    }
}
