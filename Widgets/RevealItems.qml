import QtQuick
import QtQuick.Layouts
import qs.Services

Rectangle {
    id: root
    property bool expanded: false
    property alias main: mainComponent.sourceComponent
    property alias sub: subComponent.sourceComponent
    property bool subItems: true

    color: Theme.surface
    radius: 8

    // Use Layout attached properties for sizing
    Layout.fillWidth: true
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 2
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            // Use Loader for main content with explicit sizing
            Loader {
                id: mainComponent
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 48
            }

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

        Loader {
            id: subComponent
            Layout.fillWidth: true
            clip: true
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            Layout.preferredHeight: root.expanded && item ? item.implicitHeight : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
