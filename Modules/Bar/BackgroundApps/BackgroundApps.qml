import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Services
import qs.Components
import QtQuick.Effects

Rectangle {
    id: root
    Layout.alignment: Qt.AlignRight

    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth

    color: Theme.getColor("surface_container_highest")
    border.width: 1
    border.color: Qt.darker(Theme.getColor("outline"))

    radius: 12

    // 1. Keep visible until scale hits 0
    visible: scale > 0

    // 2. Initialize at 0
    scale: 0

    readonly property bool hasContent: layout.implicitWidth > 0

    Behavior on color {
        ColorAnimation {
            easing.type: Easing.OutBack
            duration: 220
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
        }
    }

    states: [
        State {
            name: "shown"
            when: root.hasContent
            PropertyChanges {
                target: root
                scale: 1
            }
        },
        State {
            name: "hidden"
            when: !root.hasContent
            PropertyChanges {
                target: root
                scale: 0
            }
        }
    ]

    // --- FIX 2: LOGIC & NAMING ---
    transitions: [
        // POP IN (Hidden -> Shown)
        Transition {
            from: "hidden"
            to: "shown"
            ParallelAnimation {
                id: popInAnimation
                NumberAnimation {
                    target: root
                    property: "scale"
                    to: 1
                    duration: 250 // Slightly longer for bounce effect
                    easing.type: Easing.OutBack
                }
            }
        },
        // POP OUT (Shown -> Hidden)
        Transition {
            from: "shown"
            to: "hidden"
            ParallelAnimation {
                id: popOutAnimation
                NumberAnimation {
                    target: root
                    property: "scale"
                    to: 0
                    // This must be FASTER than the implicitWidth Behavior (200 < 300)
                    duration: 200
                    easing.type: Easing.InBack
                }
            }
        }
    ]

    property var activeMenuInstance: null

    RowLayout {
        id: layout
        spacing: -2
        anchors.centerIn: parent
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                implicitHeight: 24
                implicitWidth: 24

                IconImage {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 8
                    source: modelData.icon
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: backgroundAppsMouse.containsMouse ? Theme.getColor("on_tertiary_container") : Theme.getColor("on_surface")
                    }
                }

                MouseArea {
                    id: backgroundAppsMouse
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (root.activeMenuInstance) {
                                root.activeMenuInstance.close();
                                root.activeMenuInstance = null;
                            }
                            modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (root.activeMenuInstance) {
                                root.activeMenuInstance.close();
                                root.activeMenuInstance = null;
                                return;
                            }
                            if (modelData.menu) {
                                var localPos = trayItem.mapToItem(null, 0, 0);
                                var newmenu = customMenu.createObject(null, {
                                    menuHandler: modelData.menu,
                                    menuX: localPos.x,
                                    menuY: localPos.y
                                });
                                root.activeMenuInstance = newmenu;
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: customMenu
        BackgroundAppsOptions {
            Component.onDestruction: {
                if (root.activeMenuInstance === this) {
                    root.activeMenuInstance = null;
                }
            }
        }
    }
}
