import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
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
        height: root.isVisible ? contentRect.height : 0
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutQuad
            }
        }

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
            width: wallpaperGrid.width + 40
            height: wallpaperGrid.height + 40

            Rectangle {
                anchors.fill: parent
                radius: 26
                color: Theme.surface
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
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
                        onEntered: root.focusable = true
                        onClicked: textField.setFocus()
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
                    onClicked: Settings.updateMatugenColors()
                }
            }
        }
    }
}
