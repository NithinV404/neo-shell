import QtQuick
import qs.Services // Assuming this is where your Theme lives

Rectangle {
    id: root

    // --- API ---
    property bool checked: false
    signal toggled

    // --- CONFIGURATION ---
    implicitWidth: 42
    implicitHeight: 24

    // M3 Spec: Thumb is smaller when off, larger when on
    property int thumbSizeOn: 18
    property int thumbSizeOff: 18

    // --- TRACK (BACKGROUND) ---
    radius: height / 2

    // Logic: Filled Primary when ON, Transparent/Surface when OFF
    color: checked ? Theme.primary : Theme.surfaceContainerHighest

    // Logic: Border visible only when OFF
    border.width: checked ? 0 : 2
    border.color: toggleMouse.containsMouse ? Theme.tertiary : Theme.outline

    // Smooth Color Transition
    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: 200
        }
    }

    // --- THUMB (CIRCLE) ---
    Rectangle {
        id: thumb

        // Center vertically
        anchors.verticalCenter: parent.verticalCenter

        // Dynamic Size
        width: root.checked ? root.thumbSizeOn : root.thumbSizeOff
        height: width
        radius: width / 2

        // Dynamic Color: On = OnPrimary, Off = Outline
        color: root.checked ? Qt.darker(Theme.primary) : toggleMouse.containsMouse ? Theme.tertiary : Theme.outline

        // --- POSITION CALCULATION ---
        // Off: Left side + padding
        // On:  Right side - width - padding
        x: root.checked ? (root.width - width - 2) : (root.checked ? 0 : 4)
        // Note: The +4 in the 'false' logic centers the tiny thumb visually within the border area

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }
    }

    // --- INTERACTION ---
    MouseArea {
        id: toggleMouse
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggled();
        }
    }
}
