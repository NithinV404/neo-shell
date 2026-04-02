import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell
import qs.Services
import qs.Common
import qs.Widgets

PanelWindow {
    id: root

    property alias title: title.text
    property alias titleIcon: title_icon.icon
    property var menuHandler: null
    property int menuX: 0
    property int menuY: 0

    Component.onCompleted: open()

    function open() {
        menuContainer.opacity = 0;
        menuContainer.scale = 0.9;
        visible = true;
        enterAnim.start();
    }

    function close() {
        if (exitAnim.running)
            return;
        exitAnim.start();
    }

    // --- Animations ---

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
            easing.type: Easing.OutBack
        }
    }

    ParallelAnimation {
        id: exitAnim
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
        onFinished: {
            root.menuHandler = null;
            root.destroy();
        }
    }

    // --- Window setup ---

    WlrLayershell.layer: WlrLayer.Overlay

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandler
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    // Dismiss on outside click
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // --- Menu popup ---

    Rectangle {
        id: menuContainer

        x: Utils.clampScreenX(root.menuX, width, 5, root.screen)
        y: Utils.clampScreenY(root.menuY, height, 35, root.screen)

        width: 200
        height: outerColumn.implicitHeight  // driven entirely by content

        color: Theme.surfaceContainer
        radius: Settings.radius
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
        clip: true

        // Block click-through
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            id: outerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            // --- Menu items (padded) ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                spacing: 2

                Repeater {
                    model: menuOpener.children

                    delegate: Loader {
                        id: delegateLoader
                        required property var modelData
                        Layout.fillWidth: true
                        sourceComponent: modelData.isSeparator ? separatorComp : menuItemComp

                        Component {
                            id: menuItemComp
                            Rectangle {
                                implicitHeight: 30
                                color: itemHover.containsMouse ? Theme.primary : Theme.surfaceContainer
                                radius: Settings.radius

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        delegateLoader.modelData.triggered();
                                        root.close();
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8

                                    Text {
                                        text: delegateLoader.modelData.text
                                        font.family: Settings.fontFamily
                                        color: itemHover.containsMouse ? Theme.primaryFg : Theme.surfaceFg
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        antialiasing: true
                                    }
                                }
                            }
                        }

                        Component {
                            id: separatorComp
                            Item {
                                implicitHeight: 9
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4
                                    height: 1
                                    color: Theme.surfaceFg
                                    opacity: 0.5
                                }
                            }
                        }
                    }
                }
            }

            // --- Title bar (edge-to-edge, no negative margins needed) ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.secondaryContainer
                radius: Settings.radius
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    AppIcon {
                        id: title_icon
                        icon: root.title
                        size: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        id: title
                        font.family: Settings.fontFamily
                        color: Theme.surfaceFg
                        antialiasing: true
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
