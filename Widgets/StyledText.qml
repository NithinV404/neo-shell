import QtQuick.Layouts
import QtQuick
import qs.Services

Item {
    id: root

    // --- COMPATIBILITY FIX ---
    property alias text: icon.text
    // -------------------------

    property alias name: icon.text
    property alias size: icon.font.pixelSize
    property alias color: icon.color

    property bool filled: false
    property real fill: filled ? 1.0 : 0.0
    property int weight: filled ? 500 : 400

    property bool container: false
    property color containerColor: Theme.surfaceContainerHighest

    signal clicked

    // --- FIX FOR CIRCLE SHAPE ---
    // 1. Calculate the maximum dimension needed so it fits the icon
    //    and make it a square.
    readonly property real maxSize: Math.max(icon.implicitWidth, icon.implicitHeight) + 12

    // 2. Apply that same size to both Width and Height when container is true
    implicitWidth: container ? maxSize : icon.implicitWidth
    implicitHeight: container ? maxSize : icon.implicitHeight

    Layout.alignment: Qt.AlignRight

    Rectangle {
        anchors.fill: parent

        // 3. Set radius to half the height to make it a perfect circle
        radius: height / 2

        color: root.containerColor
        visible: root.container

        Behavior on color {
            ColorAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    FontLoader
    {
        id: symbolicFont
        source: Qt.resolvedUrl("../Fonts/material-symbols-rounded-latin-400-normal.ttf")
    }

    Text {
        id: icon
        anchors.centerIn: parent

        font.family: symbolicFont.name
        font.pixelSize: 24
        font.weight: 100

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
        antialiasing: true

        font.variableAxes: {
            "FILL": root.fill.toFixed(1),
            "opsz": 24,
            "wght": root.weight
        }
    }

    // --- Animations ---
    Behavior on fill {
        NumberAnimation {
            // Replaced 'Theme.shortDuration' with 200 to prevent errors if Theme is missing
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on weight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.container || root.clicked.length > 0
        onClicked: root.clicked()
    }
}
