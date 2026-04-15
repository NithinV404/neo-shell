import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Common
import qs.Services
import qs.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var screen
    property real menuX: 0
    property real menuY: 0
    property alias posX: root.menuX
    property alias posY: root.menuY
    property bool visible: false
    property bool isVisible: false

    focusable: textFieldHover.hovered || textField.focused
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

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

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        onClicked: mouse => {
            const panelContainerArea = mapToItem(panelContainer, mouse.x, mouse.y);
            const insidePanelContainerArea = (panelContainerArea.x >= 0 && panelContainerArea.x <= panelContainer.width && panelContainerArea.y >= 0 && panelContainerArea.y <= panelContainer.height);
            if (!insidePanelContainerArea) {
                root.close();
            }
        }
    }

    Item {
        id: panelContainer
        x: Utils.clampScreenX(root.menuX, width, 2, root.screen)
        y: Utils.clampScreenY(root.menuY, height, 0, root.screen)
        width: contentRect.implicitWidth
        height: contentRect.height
        clip: false
        state: root.visible ? "open" : "closed"
        transformOrigin: Item.Top

        DropShadow {
            anchors.fill: contentRect
            source: contentRect
            horizontalOffset: 0
            verticalOffset: 8
            radius: 18
            samples: 49
            color: Qt.rgba(0, 0, 0, 0.35)
            transparentBorder: true
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

        Behavior on height {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        states: [
            State {
                name: "closed"
                PropertyChanges {
                    target: panelContainer
                    opacity: 0
                    scale: 0.9
                    height: 0
                }
            },
            State {
                name: "open"
                PropertyChanges {
                    target: panelContainer
                    opacity: 1
                    scale: 1
                    height: contentRect.height
                }
            }
        ]

        transitions: [
            Transition {
                from: "closed"
                to: "open"
                NumberAnimation {
                    target: panelContainer
                    properties: "opacity,scale,height"
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
                        properties: "opacity,scale,height"
                        duration: 220
                        easing.type: Easing.InCubic
                    }
                    ScriptAction {
                        script: {
                            root.visible = false;
                            root.menuClosed();
                        }
                    }
                }
            }
        ]

        Rectangle {
            id: contentRect
            color: Theme.surface
            radius: 26
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            implicitWidth: wallpaperGrid.implicitWidth + 40
            implicitHeight: wallpaperGrid.implicitHeight + 40

            WallpaperGrid {
                id: wallpaperGrid
                anchors {
                    centerIn: parent
                }
            }

            RowLayout {
                id: floatingControls
                anchors.bottom: wallpaperGrid.bottom
                anchors.left: wallpaperGrid.left
                anchors.right: wallpaperGrid.right
                anchors.margins: 20
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
