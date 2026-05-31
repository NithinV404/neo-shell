import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Item {
    id: root
    clip: true
    property bool editMode: false

    enum WidgetSize {
        Compact,
        Normal
    }

    readonly property point parentPos: root.mapToItem(null, 0, 0)
    property int widgetSize: QuickToggle.WidgetSize.Normal
    property bool isCompact: root.widgetSize === QuickToggle.WidgetSize.Compact

    property real baseWidth: isCompact ? 60 : 160
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

    signal size
    signal clicked
    signal menuClicked

    property color activeColor: Theme.primary
    property color activeHoverColor: Qt.darker(Theme.primary)
    property color inactiveColor: Theme.surfaceContainerHigh
    property color inactiveHoverColor: Qt.darker(Theme.surfaceContainerHigh)

    property bool isIconHovered: toggleButtonMouse.containsMouse
    property bool isTextHovered: textAreaMouse.containsMouse
    property bool isAnyHovered: isIconHovered || isTextHovered

    // Main background color
    property color mainBg: {
        if (root.active && (isCompact || !root.hasSubMenu)) {
            return isAnyHovered ? activeHoverColor : activeColor;
        } else {
            return isAnyHovered ? inactiveHoverColor : inactiveColor;
        }
    }

    // Icon box background color
    property color iconBg: {
        if (isCompact || !root.hasSubMenu) {
            return "transparent";
        }
        if (root.active) {
            return isIconHovered ? activeHoverColor : activeColor;
        } else {
            return isIconHovered ? inactiveHoverColor : inactiveColor;
        }
    }

    scale: toggleButtonMouse.pressed || textAreaMouse.pressed ? 0.95 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutBack
        }
    }

    Rectangle {
        id: quickToggle
        anchors.fill: parent
        radius: root.radius
        color: root.mainBg

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

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
    }

    Rectangle {
        id: editOverlay
        anchors.fill: quickToggle
        visible: root.editMode
        color: "transparent"
        radius: root.radius
        border.width: 2
        border.color: Theme.primary

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: Theme.primary
            width: 20
            height: 20
            radius: 4

            StyledText {
                anchors.centerIn: parent
                text: "edit"
                color: Theme.primaryFg
                size: 11
            }
            DragHandler {
                id: modeDrag
                target: null

                onActiveChanged: {
                    if (!active) {
                        root.baseWidth = root.isCompact ? 60 : 160;
                        root.baseHeight = 50;
                        root.size();
                    }
                }

                onCentroidChanged: {
                    var dx = centroid.scenePosition.x - centroid.scenePressPosition.x;
                    if (dx < -20) {
                        root.widgetSize = QuickToggle.WidgetSize.Compact;
                    } else if (dx > 20) {
                        root.widgetSize = QuickToggle.WidgetSize.Normal;
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8

        // Icon Box
        Rectangle {
            id: toggleBox
            Layout.fillHeight: true
            Layout.preferredWidth: isCompact ? root.baseWidth - (root.padding * 2) : height
            Layout.alignment: Qt.AlignHCenter

            color: root.iconBg
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
                enabled: !root.editMode
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Effects.animation.ripple(root, root.parentPos.x, root.parentPos.y);
                    root.clicked();
                }
                onPressAndHold: {
                    if (root.hasSubMenu)
                        root.menuClicked();
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Completely remove from layout if compact
            visible: !isCompact

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

            MouseArea {
                id: textAreaMouse
                anchors.fill: parent
                enabled: !root.editMode
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Effects.animation.ripple(root, root.parentPos.x, root.parentPos.y);
                    if (root.hasSubMenu) {
                        root.menuClicked();
                    } else {
                        root.clicked();
                    }
                }
            }
        }
    }
}
