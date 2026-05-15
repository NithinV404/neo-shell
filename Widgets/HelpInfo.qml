import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Common

Rectangle {
    id: root
    property string icon: "help"
    property string description: ""
    property string title: "Title"
    height: content.height
    width: content.width
    color: "transparent"
    ColumnLayout {
        id: content
        anchors.centerIn: parent
        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: {
                root.icon;
            }
            color: Theme.surfaceFg
            size: 32
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            text: root.title
            font.pixelSize: 20
            font.family: Settings.fontFamily
            color: Theme.surfaceFg
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            text: root.description
            font.pixelSize: 12
            font.family: Settings.fontFamily
            color: Theme.surfaceFg
        }
    }
}
