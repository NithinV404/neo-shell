// Clock.qml
import QtQuick
import QtQuick.Layouts
import Shell.Services

Rectangle {
    id: root
    property bool hovered: false
    property date time_date: new Date();
    width: timeRow.implicitWidth + 30
    height: 28
    color: "transparent"
    radius: 12

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: timeRow
        anchors.centerIn: parent
        spacing: 4

        // Time
        Text {
            id: textTime
            text: Qt.formatDateTime(root.time_date, "hh:mm AP")
            color: ThemeManager.onSurface
            font.pixelSize: Math.round(root.height * 0.4)
            font.weight: 500
            font.family: "Adwaita Sans"
            Layout.alignment: Qt.AlignCenter
            renderType: Text.QtRendering
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 4
            Layout.preferredHeight: 4
            radius: 12
            color: ThemeManager.onSurface
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: Qt.formatDateTime(root.time_date, "ddd MM/dd")
            color: ThemeManager.onSurface
            font.pixelSize: Math.round(root.height * 0.4)
            font.weight: 500
            font.family: "Adwaita Sans"
            Layout.alignment: Qt.AlignCenter
            renderType: Text.NativeRendering
            font.hintingPreference: Font.PreferFullHinting
        }
    }
}
