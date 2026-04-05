import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Services
import qs.Common

Item {
    id: root

    property string placeholder: ""
    property alias text: inputField.text
    property bool password: false
    property bool showPassword: false
    property bool edit: false
    readonly property bool focused: inputField.activeFocus

    signal editingFinished
    signal accepted

    function clear() {
        inputField.text = "";
    }

    function setFocus() {
        inputField.focus = true;
    }

    function clearFocus() {
        inputField.focus = false;
    }

    Component.onDestruction: clearFocus()

    implicitWidth: 300
    implicitHeight: 60

    DropShadow {
        anchors.fill: backgroundRect
        source: backgroundRect
        horizontalOffset: 0
        verticalOffset: 6
        radius: 16
        samples: 41
        color: Qt.rgba(0, 0, 0, 0.25)
        transparentBorder: true
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        height: 80

        radius: Settings.radius
        color: Theme.surfaceContainer
        border.color: inputField.activeFocus ? Theme.tertiary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: inputField.activeFocus ? 1.5 : 1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 8

            TextInput {
                id: inputField
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.surfaceVariantFg
                font.pixelSize: 16
                font.family: Settings.fontFamily
                clip: true
                echoMode: root.password && !root.showPassword ? TextInput.Password : TextInput.Normal
                selectByMouse: true
                selectionColor: Theme.tertiary
                selectedTextColor: Theme.tertiaryFg
                onAccepted: root.accepted()
                text: root.edit ? root.placeholder : ""
                activeFocusOnPress: true
                onEditingFinished: root.editingFinished

                Text {
                    anchors.fill: parent
                    font.family: Settings.fontFamily
                    text: root.placeholder
                    color: Theme.surfaceVariantFg
                    font.pixelSize: 16
                    visible: !inputField.text && !inputField.activeFocus
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                visible: root.password
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 16
                color: toggleMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: root.showPassword ? "visibility_off" : "visibility"
                    size: 20
                    color: Theme.surfaceVariantFg
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
}
