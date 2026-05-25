import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.SystemTray
import Quickshell
import qs.Services
import qs.Widgets
import qs.Common
import qs.Modules.Bar.SystemTrayPanel

Rectangle {
    id: root

    height: 28
    width: layout.implicitWidth + 4

    color: "transparent" //  Theme.surfaceContainerHighest
    // border.width: 1
    // border.color: Qt.darker(Theme.outline)

    radius: Settings.radius
    visible: scale > 0
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
        spacing: 0
        anchors.centerIn: parent
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property var modelData
                implicitHeight: 24
                implicitWidth: 24

                AppIcon {
                    anchors.centerIn: parent
                    size: root.height * 0.6
                    icon: {
                        return trayItem.modelData.icon;
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Theme.tertiary
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
                            modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) {
                                var localPos = trayItem.mapToItem(null, 0, 0);
                                systemTrayPanel.active = true;
                                systemTrayPanel.item.open(localPos.x, localPos.y + 34, trayItem.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
    LazyLoader {
        id: systemTrayPanel
        active: false
        SystemTrayPanel {
            onMenuClosed: {
                systemTrayPanel.active = false;
            }
        }
    }
}
