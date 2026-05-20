import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Common
import qs.Services
import qs.Widgets

Popout {
    id: root

    content: Item {
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

        Item {
            id: contentRect
            clip: true
            width: wallpaperGrid.width + 40
            height: root.isVisible ? wallpaperGrid.height + 40 : 0
            opacity: root.isVisible ? 1 : 0
            layer.enabled: root.shadowEnabled
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 18
                samples: 49
                color: Qt.rgba(0, 0, 0, 0.35)
                transparentBorder: true
            }

            Rectangle {
                anchors.fill: parent
                radius: 26
                color: Theme.surface
                opacity: contentRect.opacity
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            }

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
                    height: 42

                    MouseArea {
                        id: textFieldMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            root.focusable = true;
                        }
                        onClicked: {
                            textField.setFocus();
                        }
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
