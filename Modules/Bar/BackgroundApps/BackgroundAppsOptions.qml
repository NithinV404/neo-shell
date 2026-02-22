import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Wayland // Required for WlrLayershell
import Quickshell
import qs.Services
import qs.Common

PanelWindow {
    id: root

    property var menuHandler: null
    property int menuX: 0
    property int menuY: 0

    Component.onCompleted: {
        // Automatically animate IN when created
        open();
    }

    function open() {
        menuContainer.opacity = 0;
        menuContainer.scale = 0.9;
        visible = true;
        enterAnim.start();
    }

    function close() {
        if (exitAnim.running) {
            return;
        }
        // Start exit animation
        exitAnim.start();
    }

    // --- ANIMATIONS ---
    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: menuContainer
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: menuContainer
            property: "scale"
            from: 0.9
            to: 1
            duration: 200
            easing.type: Easing.OutBack // Gives it a nice "pop" effect

        }
    }

    ParallelAnimation {
        id: exitAnim
        // Run these animations...
        NumberAnimation {
            target: menuContainer
            property: "opacity"
            from: 1
            to: 0
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: menuContainer
            property: "scale"
            from: 1
            to: 0.95
            duration: 150
        }

        // ...and when done, actually hide the window
        onFinished: {
            root.menuHandler = null;
            root.destroy();
        }
    }

    // LAYER SETTINGS
    WlrLayershell.layer: WlrLayer.Overlay

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandler
    }

    // Use specific anchors instead of fill: true (safer)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    // SHIELD (Click outside to close)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.close()
    }

    // MENU BOX
    Rectangle {
        id: menuContainer
        x: Utils.clampScreenX(root.menuX, width, 5)
        // 2. Vertical Clamp: Flip up if at bottom of screen
        y: Utils.clampScreenY(root.menuY, height, 35)

        width: 200
        // Ensure height is never 0 to prevent drawing errors
        height: Math.max(layout.implicitHeight + 10, 20)

        color: Theme.surfaceContainer
        radius: 12
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 5
            spacing: 2

            Repeater {
                id: menuRepeater
                model: menuOpener.children

                // Model is set via alias
                //

                delegate: Loader {
                    id: loader
                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separatorComp : itemComp

                    Component {
                        id: itemComp
                        Rectangle {
                            implicitHeight: 30
                            Layout.fillWidth: true
                            color: optionsHover.containsMouse ? Theme.primary : Theme.surface
                            radius: 6

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: optionsHover
                                anchors.fill: parent
                                onClicked: {
                                    modelData.triggered();
                                    root.close();
                                }
                                hoverEnabled: true
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                Text {
                                    text: modelData.text
                                    font.family: Settings.fontFamily
                                    color: !optionsHover.containsMouse ? Theme.surfaceFg : Theme.primaryFg
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    antialiasing: true
                                }
                            }
                        }
                    }

                    Component {
                        id: separatorComp
                        Rectangle {
                            implicitHeight: 1
                            Layout.fillWidth: true
                            Layout.margins: 4
                            color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }
}
