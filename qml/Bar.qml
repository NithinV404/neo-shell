import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Shell.Services
import Shell.Widgets

Window {
    id: root
    visible: false
    width: Screen.width
    height: 30
    color: "transparent"
    flags: Qt.FramelessWindowHint

    Rectangle {
        id: bar
        width: parent.width
        height: parent.height
        radius: 12
        color: ThemeManager.surface
        border.width: 1
        border.color: ThemeManager.primary

        RowLayout {
            id: workspaceRow
            spacing: 10
            anchors.fill: parent
            Layout.margins: 4

            ListView {
                id: workspaceListView
                Layout.leftMargin: 8
                // Don't fillWidth! Let it size to its content so windows can be seen.
                Layout.preferredWidth: contentItem.childrenRect.width
                Layout.preferredHeight: parent.height - 8
                orientation: ListView.Horizontal
                spacing: 4

                model: NiriWorkspaces

                delegate: Rectangle {
                    width: 20
                    height: 22
                    radius: 4
                    color: model.isActive ? ThemeManager.tertiary : ThemeManager.surfaceContainerHighest

                    Text {
                        anchors.centerIn: parent
                        text: model.wsIndex
                        color: model.isActive ? ThemeManager.onTertiary : ThemeManager.onSurface
                    }
                }
            }

            // This Rectangle is now a SIBLING to the ListView, not inside the delegate
            Rectangle {
                Layout.fillWidth: true // Take up remaining space
                Layout.topMargin: 4
                Layout.preferredHeight: 22
                Layout.rightMargin: 8
                color: ThemeManager.surface

                // This requires you to have added the Q_PROPERTY(QVariantList activeWorkspaceWindows)
                // to your C++ WorkspaceModel as shown in the previous answer!
                Text {
                        // Use modelData instead of model for QVariantList of Q_GADGETs
                        text: NiriWorkspaces.focusedWindowTitle  || " "
                        font.family: "Adwaita Sans"
                        font.pixelSize: 12
                        color: ThemeManager.onSurface
                        elide: Text.ElideRight // Prevent text from overlapping the clock
                        renderType: Text.QtRendering
                    }
            }

            Clock {
                id: clock
                height: 30
            }
        }
    }
}
