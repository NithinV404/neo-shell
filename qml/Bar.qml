import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Shell.Services
import Shell.Widgets

PanelWindow {
    id: root
    visible: true
    layer: PanelWindow.Top
    anchors: PanelWindow.AnchorTop | PanelWindow.AnchorLeft | PanelWindow.AnchorRight
    exclusionZone: 32
    keyboardInteractivity: PanelWindow.None
    color: "transparent"
    height: 32

    Rectangle {
        id: bar
        anchors.fill: parent
        radius: 12
        color: ThemeManager.surface
        border.width: 1
        border.color: ThemeManager.primary

        Component.onCompleted: {
            console.info(ThemeManager.primary.r, ThemeManager.primary.g, ThemeManager.primary.b, ThemeManager.primary.a )
        }

        RowLayout {
            id: workspaceRow
            spacing: 10
            anchors.fill: parent
            Layout.margins: 4

            ListView {
                id: workspaceListView
                Layout.leftMargin: 8
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

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                Layout.preferredHeight: 20
                Layout.rightMargin: 8
                color: ThemeManager.surface

                Text {
                    width: 400
                    text: NiriWorkspaces.focusedWindowTitle || " "
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                    color: ThemeManager.onSurface
                    elide: Text.ElideRight
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
