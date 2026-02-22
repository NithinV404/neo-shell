import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root

    // --- 1. API ---
    property string icon: "help"
    property alias title: subText.text
    property alias status: subTextInfo.text

    // The most important part of a toggle: Is it ON or OFF?
    property bool active: false

    property int setPadding: 4
    property int setRadius: 28 //

    signal clicked
    signal menuClicked

    // --- 2. APPEARANCE ---

    radius: setRadius

    // Color Logic:
    // ON  = Primary Color (Colorful)
    // OFF = Surface Container Highest (Dark Grey/Neutral)
    color: Theme.surfaceContainerHighest

    // Smooth color transition
    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    // --- 3. INTERACTION ---

    // Hover Overlay (Makes it lighten slightly when hovered)
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "white"
        opacity: mouseArea.containsMouse ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.setPadding
        spacing: 12 // A bit more breathing room between icon and text

        // --- 4. ICON CONTAINER ---
        Rectangle {
            id: toggleBox
            Layout.fillHeight: true
            // TRICK: Make width match height to keep it a perfect circle/square
            Layout.preferredWidth: height

            // Color Logic:
            // ON  = Dark Text on Bright Background -> Icon Box becomes transparent or slightly darkened
            // OFF = Grey Background -> Icon Box becomes the "Primary" accent
            color: root.active ? Qt.darker(Theme.primary, 1.2) // Subtle highlight on active
            : toggleButton.containsMouse ? Theme.tertiary : Theme.surfaceDim

            radius: root.radius - root.setPadding

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            StyledText {
                name: root.icon
                anchors.centerIn: parent
                size: 20 // Slightly larger icon

                // Icon Color: Contrast against the box
                color: root.active ? Theme.primaryFg : toggleButton.containsMouse ? Theme.tertiaryFg : Theme.secondaryContainerFg
            }

            MouseArea {
                id: toggleButton
                anchors.fill: parent
                onClicked: root.clicked()
                hoverEnabled: true
            }
        }

        Item {
            // 1. Layout Properties (Since parent is RowLayout)
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 2. The Text Content
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
                    color: Theme.surfaceFg
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
                    color: Theme.surfaceFg
                    font.family: Settings.fontFamily
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    elide: Text.ElideRight
                }
            }

            // 3. The MouseArea (LAST CHILD = ON TOP)
            MouseArea {
                id: menuToggle
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.menuClicked()
            }
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor
    }
}
