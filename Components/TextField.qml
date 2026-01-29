import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root

    property string placeholder: ""
    property string text: inputField.text
    property bool password: false
    property bool showPassword: false

    signal accepted

    function clear() {
        inputField.text = "";
    }

    function setFocus() {
        inputField.forceActiveFocus();
    }
    Component.onDestruction: {
        inputField.focus = false;
    }

    implicitWidth: 300
    implicitHeight: 56
    radius: 12
    color: Theme.getColor("surface_container")
    border.color: inputField.activeFocus ? Theme.getColor("primary") : Theme.getColor("outline")
    border.width: inputField.activeFocus ? 2 : 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 8

        TextInput {
            id: inputField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: Theme.getColor("on_surface")
            font.pixelSize: 16
            font.family: Settings.fontFamily
            clip: true
            echoMode: root.password && !root.showPassword ? TextInput.Password : TextInput.Normal
            selectByMouse: true
            selectionColor: Theme.getColor("primary")
            selectedTextColor: Theme.getColor("on_primary")
            onTextChanged: root.textChanged
            onAccepted: root.accepted()

            Text {
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                font.family: Settings.fontFamily
                text: root.placeholder
                color: Theme.getColor("on_surface_variant")
                font.pixelSize: 16
                visible: !inputField.text && !inputField.activeFocus
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Toggle password visibility button
        Rectangle {
            visible: root.password
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: 16
            color: toggleMouse.containsMouse ? Theme.getColor("surface_container_high") : "transparent"

            StyledText {
                anchors.centerIn: parent
                text: root.showPassword ? "visibility_off" : "visibility"  // Nerd font icons (eye / eye-off)
                size: 20
                color: Theme.getColor("on_surface_variant")
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
                onClicked: root.showPassword = !root.showPassword
            }
        }
    }
}
