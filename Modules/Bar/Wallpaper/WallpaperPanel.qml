import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Common
import qs.Services
import qs.Widgets

Popout {
    id: root
    focusable: textFieldHover.hovered || textField.focused
    readonly property int animationDuration: 300
    property alias enableShadow: shadowRect.layer.enabled

    Component.onCompleted: {
        openAnimationTimer.running = true;
    }

    onIsVisibleChanged: {
        if (!isVisible) {
            root.enableShadow = false;
            closeAnimationTimer.running = true;
        }
    }

    Item {
        id: panelContainer
        x: Utils.clampScreenX(root.panelX - (width / 2), width, 0, root.screen)
        y: Utils.clampScreenY(root.panelY, height, 0, root.screen)
        width: contentRect.width
        height: contentRect.height

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => {
                const inputFieldArea = mapToItem(textField, mouse.x, mouse.y);
                const insideInputFieldArea = (inputFieldArea.x >= 0 && inputFieldArea.x <= textField.width && inputFieldArea.y >= 0 && inputFieldArea.y <= textField.height);
                if (!insideInputFieldArea) {
                    textField.clearFocus();
                }
                mouse.accepted = false;
            }
        }

        Rectangle {
            id: shadowRect
            width: contentRect.width
            height: contentRect.height
            radius: 26
            color: Theme.surface
            opacity: contentRect.opacity
            layer.enabled: false
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 18
                samples: 49
                color: Qt.rgba(0, 0, 0, 0.35)
                transparentBorder: true
            }
        }

        Item {
            id: contentRect
            clip: true
            width: wallpaperGrid.width + 40
            height: root.isVisible ? wallpaperGrid.height + 40 : 0
            opacity: root.isVisible ? 1 : 0

            Timer {
                id: openAnimationTimer
                interval: root.animationDuration
                running: false
                onTriggered: {
                    root.enableShadow = true;
                }
            }

            Timer {
                id: closeAnimationTimer
                interval: root.animationDuration
                onTriggered: {
                    if (!root.isVisible) {
                        root.visible = false;
                        root.menuClosed();
                    }
                }
            }

            Behavior on opacity {
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
            WallpaperGrid {
                id: wallpaperGrid
                x: 20
                y: 20
            }

            RowLayout {
                id: floatingControls
                anchors.bottom: wallpaperGrid.bottom
                anchors.left: wallpaperGrid.left
                anchors.right: wallpaperGrid.right
                spacing: 12
                z: 2

                InputField {
                    id: textField
                    Layout.fillWidth: true
                    placeholder: Settings.wallpapersFolder
                    edit: true
                    implicitHeight: 40

                    HoverHandler {
                        id: textFieldHover
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            textField.clearFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Settings.saveWallpapersFolderPath(textField.text);
                            textField.clearFocus();
                        }
                    }
                }

                Button {
                    icon: "save"
                    text: "Save"
                    implicitHeight: 40
                    bgColor: Theme.primary
                    textColor: Theme.primaryFg
                    onClicked: {
                        Settings.saveWallpapersFolderPath(textField.text);
                        textField.clearFocus();
                    }
                }

                Button {
                    icon: "refresh"
                    text: "Regenerate"
                    implicitHeight: 40
                    bgColor: Theme.primary
                    textColor: Theme.primaryFg
                    onClicked: {
                        Settings.updateMatugenColors();
                    }
                }
            }
        }
    }
}
