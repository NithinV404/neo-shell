import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root
    clip: true

    enum WidgetSize {
        One,
        Two
    }

    readonly property point parentPos: root.mapToItem(null, 0, 0)
    property int widgetSize: QuickToggle.WidgetSize.Two
    property string icon: "help"
    property alias title: subText.text
    property alias status: subTextInfo.text
    property bool hasSubMenu: true
    property bool active: false
    property int setPadding: 6
    property int setRadius: active ? Settings.radius - 4 : Settings.radius

    signal clicked
    signal menuClicked

    radius: setRadius
    scale: toggleMenuMouse.pressed || toggleButtonMouse.pressed ? 0.95 : 1
    color: (!root.hasSubMenu && root.active) ? Theme.primary : Theme.surfaceContainerHigh

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutBack
        }
    }

    Behavior on radius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutBack
        }
    }

    MouseArea {
        id: toggleMenuMouse
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Effects.animation.ripple(root, root.parentPos.x, root.parentPos.y);
            root.hasSubMenu ? root.menuClicked() : root.clicked();
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: root.radius
        color: "white"
        opacity: toggleMenuMouse.containsMouse ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.setPadding
        spacing: 8

        Rectangle {
            id: toggleBox
            Layout.fillHeight: true
            Layout.preferredWidth: height

            color: {
                if (!root.hasSubMenu && root.active)
                    return "transparent";
                if (root.active)
                    return !root.hasSubMenu ? Theme.primary : Qt.darker(Theme.primary, 1.2);
                if (toggleButtonMouse.containsMouse)
                    return Theme.tertiary;
                return root.hasSubMenu ? Theme.surfaceContainerLow : "transparent";
            }

            radius: root.radius - root.setPadding

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            StyledText {
                name: root.icon
                anchors.centerIn: parent
                size: 20
                color: root.active ? Theme.primaryFg : (toggleButtonMouse.containsMouse ? Theme.tertiaryFg : Theme.secondaryContainerFg)
            }

            MouseArea {
                id: toggleButtonMouse
                anchors.fill: parent
                onClicked: {
                    Effects.animation.ripple(root, root.parentPos.x, root.parentPos.y);
                    root.clicked();
                }
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            Layout.fillWidth: visible
            Layout.fillHeight: true
            visible: root.widgetSize === QuickToggle.WidgetSize.Two
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
