import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services
import qs.Common

Rectangle {
    id: root
    property string icon: "help"
    property string description: ""
    property string title: "Title"
    implicitHeight: content.height
    implicitWidth: content.width
    color: "transparent"
    ColumnLayout {
        id: content
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        anchors.centerIn: parent
        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: {
                root.icon;
            }
            color: Theme.getColor("on_surface")
            size: 32
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            text: root.title
            font.pixelSize: 20
            font.family: Settings.fontFamily
            color: Theme.getColor("on_surface")
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            text: root.description
            font.pixelSize: 12
            font.family: Settings.fontFamily
            color: Theme.getColor("on_surface")
        }
    }
}
