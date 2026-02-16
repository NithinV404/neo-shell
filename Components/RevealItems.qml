import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root
    property bool expanded: false
    property alias main: mainComponent.children
    property alias sub: subComponent.children
    property bool subItems: true

    color: Theme.surface
    radius: 8

    // Proper size calculation
    implicitWidth: contentLayout.implicitWidth + 16
    implicitHeight: contentLayout.implicitHeight + 16

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 2
        spacing: 8

        // Main row with content + arrow
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            // Container for main content
            Item {
                id: mainComponent
                Layout.fillWidth: true
                implicitHeight: childrenRect.height
                implicitWidth: childrenRect.width
            }

            // Arrow button on the right
            StyledText {
                id: dropdown_icon
                name: "keyboard_arrow_down"
                rotation: root.expanded ? 180 : 0
                Layout.margins: 4
                color: Theme.surfaceFg
                visible: root.subItems

                Behavior on rotation {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.expanded = !root.expanded
                }
            }
        }

        // Expandable sub content
        Item {
            id: subComponent
            Layout.fillWidth: true
            clip: true
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            implicitHeight: childrenRect.height
            implicitWidth: childrenRect.width

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
