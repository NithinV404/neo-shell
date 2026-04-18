import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root
    property bool expanded: false
    property alias main: mainComponent.sourceComponent
    property alias sub: subComponent.sourceComponent
    property bool subItems: true

    color: Theme.surface
    radius: Settings.radius

    // Use Layout attached properties for sizing
    Layout.fillWidth: true

    height: contentLayout.implicitHeight

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.centerIn: parent
        width: parent.width - 20
        spacing: 0

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            spacing: 0

            // Use Loader for main content with explicit sizing
            Loader {
                id: mainComponent
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 48
                Layout.alignment: Qt.AlignCenter
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
