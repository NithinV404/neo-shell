import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Common
import qs.Modules.Bar.ControlCenterPanel

Popout {
    id: root
    hAlign: "center"

    content: Item {
        id: panelContainer
        readonly property real targetWidth: quickLayoutStack.itemWidth + 24
        readonly property real targetHeight: quickLayoutStack.itemHeight + 24
        height: root.isVisible ? quickLayoutStack.itemHeight + 24 : 0
        width: quickLayoutStack.itemWidth + 24

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
            anchors.fill: parent
            radius: Settings.radius
            color: Theme.surface
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        }

        StackLayout {
            id: quickLayoutStack
            property real itemWidth: children[currentIndex].implicitWidth
            property real itemHeight: children[currentIndex].implicitHeight
            property int previousIndex: 0
            currentIndex: 0
            clip: true
            anchors.fill: parent
            anchors.margins: 12

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
