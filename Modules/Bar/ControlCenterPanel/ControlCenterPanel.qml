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
        x: Utils.clampScreenX(root.panelX, width, 5, root.screen)
        y: Utils.clampScreenY(root.panelY, height, 0, root.screen)
        width: quickLayoutStack.itemWidth + 24
        height: root.isVisible ? quickLayoutStack.itemHeight + 24 : 0
        opacity: root.isVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {  
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutBack
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
            readonly property var currentItem: children[currentIndex] && children[currentIndex].item
            readonly property int itemHeight: (currentItem && currentItem.implicitHeight) ?? controlPanel.implicitHeight
            readonly property int itemWidth: (currentItem && currentItem.implicitWidth) ?? controlPanel.implicitWidth

            height: itemHeight
            width: itemWidth
            currentIndex: 0
            clip: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            x: 12
            y: 12

            ControlCenter {
                id: controlPanel
                screen: root.screen
            }

            Loader {
                id: wifiPanelPanel
                sourceComponent: Network {
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }

            Loader {
                id: bluetoothPanel
                sourceComponent: Bluetooth {
                    bluetooth: BluetoothService
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }

            Loader {
                id: audioPanel
                sourceComponent: Audio {
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }
        }
    }
}
