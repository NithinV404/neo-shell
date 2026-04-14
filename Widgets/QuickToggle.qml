import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Item {
    id: root
    clip: true

    enum WidgetSize {
        Compact,
        Normal
    }

    readonly property point parentPos: root.mapToItem(null, 0, 0)
    property int widgetSize: QuickToggle.WidgetSize.Normal
    property real baseWidth: {
        switch (widgetSize) {
        case QuickToggle.WidgetSize.Normal:
            return 160;
        case QuickToggle.WidgetSize.Compact:
            return 60;
        default:
            return 160;
        }
    }

    property real baseHeight: 50
    property string icon: "help"
    property alias title: subText.text
    property alias status: subTextInfo.text
    property bool hasSubMenu: true
    property bool active: false
    property int padding: 6
    property int radius: active ? Settings.radius - 4 : Settings.radius

    implicitHeight: baseHeight
    implicitWidth: baseWidth

    signal clicked
    signal menuClicked

    Rectangle {
        id: quickToggle
        anchors.fill: parent
        radius: root.radius
        color: {
            if (!root.hasSubMenu) {
                if (root.active) {
                    if (root.widgetSize === QuickToggle.WidgetSize.Compact) {
                        return toggleButtonMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary;
                    } else {
                        return toggleMenuMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary;
                    }
                } else {
                    return toggleButtonMouse.containsMouse ? Qt.darker(Theme.surfaceContainerHigh) : Theme.surfaceContainerHigh;
                }
            } else {
                if (root.active) {
                    return toggleMenuMouse.containsMouse ? Qt.darker(Theme.surfaceContainerHigh) : Theme.surfaceContainerHigh;
                } else {
                    return toggleMenuMouse.containsMouse ? Qt.darker(Theme.surfaceContainerHigh) : Theme.surfaceContainerHigh;
                }
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    scale: toggleMenuMouse.pressed || toggleButtonMouse.pressed ? 0.95 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutBack
        }
    }

    MouseArea {
        id: toggleMenuMouse
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Effects.animation.ripple(root, root.parentPos.x, root.parentPos.y);
            if (root.hasSubMenu)
                root.menuClicked();
            else
                root.clicked();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8

        Rectangle {
            id: toggleBox
            Layout.fillHeight: true
            Layout.preferredWidth: height
            Layout.alignment: root.widgetSize === QuickToggle.WidgetSize.Normal ? Qt.AlignLeft : Qt.AlignHCenter

            color: {
                {
                    if (!root.hasSubMenu) {
                        return "transparent";
                    } else {
                        if (root.active) {
                            return toggleButtonMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary;
                        } else {
                            return toggleButtonMouse.containsMouse ? Qt.darker(Theme.surfaceContainerHigh) : Theme.surfaceContainerHigh;
                        }
                    }
                }
            }

            radius: root.radius - root.padding

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            StyledText {
                name: root.icon
                anchors.centerIn: parent
                size: 20
                color: root.active ? Theme.primaryFg : Theme.surfaceFg
            }

            MouseArea {
                id: toggleButtonMouse
                anchors.fill: parent
                onClicked: {
                    root.clicked();
                }
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: root.widgetSize === QuickToggle.WidgetSize.Normal ? -1 : 0
            Layout.fillHeight: true
            visible: root.widgetSize === QuickToggle.WidgetSize.Normal

            ColumnLayout {
                id: textCol
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 0

                Text {
                    id: subText
                    text: "Title"
                    font.weight: 600
                    font.pixelSize: 14
                    color: (root.active && !root.hasSubMenu) ? Theme.primaryFg : Theme.surfaceFg
                    font.family: Settings.fontFamily
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    elide: Text.ElideRight
                }

                Text {
                    id: subTextInfo
                    text: "Status"
                    visible: text !== ""
                    font.weight: 400
                    font.pixelSize: 12
                    opacity: 0.8
                    color: (root.active && !root.hasSubMenu) ? Theme.primaryFg : Theme.surfaceFg
                    font.family: Settings.fontFamily
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    elide: Text.ElideRight
                }
            }
        }
    }
}
