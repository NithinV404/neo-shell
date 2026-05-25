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

    property bool isVisible: false
    property alias title: title.text
    property alias titleIcon: title_icon.icon
    property var menuHandler: null
    property real menuX: 0
    property real menuY: 0

    signal menuClosed

    onMenuHandlerChanged: {
        if (menuHandler) {
            const opener = menuItemsRetriver(menuHandler.menu);
            opener.onChildrenChanged.connect(() => {
                itemsRepeater.model = opener.children;
            });
        }
    }

    function open(x, y, menu) {
        root.menuX = x;
        root.menuY = y;
        root.menuHandler = menu;
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        if (animationTimer.running)
            return;
        root.isVisible = false;
        animationTimer.start();
    }

    Timer {
        id: animationTimer
        interval: 300
        onTriggered: {
            root.visible = false;
            root.menuClosed();
        }
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    function menuItemsRetriver(menu): QtObject {
        const qsMenuOpenerQml = Qt.createQmlObject(`import Quickshell; QsMenuOpener{}`, root);
        qsMenuOpenerQml.menu = menu;
        return qsMenuOpenerQml;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: menuContainer
        x: Utils.clampScreenX(root.menuX, width, 0, root.screen)
        y: Utils.clampScreenY(root.menuY, height, 0, root.screen)
        clip: true
        width: 224
        height: root.isVisible ? backgroundRect.height + 24 : 0
        scale: root.isVisible ? 1 : 0
        opacity: root.isVisible ? 1 : 0
        transformOrigin: Item.Top

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: backgroundRect
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 0

            height: outerColumn.implicitHeight

            color: Theme.surface
            radius: Settings.radius
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            clip: true

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }

            ColumnLayout {
                id: outerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 2

                    Repeater {
                        id: itemsRepeater

                        delegate: Loader {
                            id: delegateLoader
                            required property var modelData
                            Layout.fillWidth: true
                            sourceComponent: modelData.isSeparator ? separatorComp : menuItemComp

                            Component {
                                id: menuItemComp
                                Rectangle {
                                    id: item
                                    property point pos: item.mapFromGlobal(0, null)
                                    implicitHeight: 30
                                    color: itemHover.containsMouse ? Theme.surfaceContainerHighest : Theme.surface
                                    radius: Settings.radius
                                    clip: true

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    MouseArea {
                                        id: itemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            Effects.animation.ripple(item, pos.x, pos.y);
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
                                            color: itemHover.containsMouse ? Theme.surfaceFg : Theme.surfaceFg
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

                Rectangle {
                    Layout.bottomMargin: 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2
                    height: 38
                    color: Theme.surfaceContainer
                    radius: Settings.radius - 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        AppIcon {
                            id: title_icon
                            icon: root.menuHandler?.icon ?? ""
                            size: 20
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            id: title
                            text: root.menuHandler?.id ?? root.menuHandler?.title ?? root.menuHandler?.tooltipTitle ?? ""
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
}
