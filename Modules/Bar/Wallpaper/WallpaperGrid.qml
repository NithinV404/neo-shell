import QtQuick
import Quickshell.Io
import Quickshell
import Qt5Compat.GraphicalEffects
import qs.Services
import qs.Components
import qs.Common

Item {
    id: root
    property int cellWidth: 200
    property int cellHeight: 100
    property int padding: 12
    property int spacing: 8
    property int cellSize: 100
    property int noOfCols: 5
    // GridView cellWidth includes spacing
    readonly property int gridCellWidth: cellWidth + spacing
    readonly property int gridCellHeight: cellHeight + spacing

    // Match exactly what GridView needs
    implicitWidth: (gridCellWidth * noOfCols) + (padding * 2)
    implicitHeight: Math.min(300, (gridCellHeight * 3) + (padding * 2))
    property string folderPath: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var imageFiles: []

    Component.onCompleted: {
        root.imageFiles = Settings.wallpaperFolderImages;
    }

    Timer {
        id: wallpaperRefreshTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            listProcess.running = true;
        }
    }

    Process {
        id: listProcess
        command: ["sh", "-c", "ls -1 \"" + root.folderPath + "\" | grep -iE '\\.(jpg|jpeg|png|webp|gif|bmp)$'"]
        running: false

        property var tempFiles: []

        onRunningChanged: {
            if (running) {
                tempFiles = [];
            }
        }

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (trimmed !== "") {
                    listProcess.tempFiles.push(root.folderPath + "/" + trimmed);
                }
            }
        }

        onExited: {
            const oldFiles = root.imageFiles ?? [];
            const newFiles = listProcess.tempFiles ?? [];
            const oldSorted = JSON.stringify([...oldFiles].sort());
            const newSorted = JSON.stringify([...newFiles].sort());

            if (oldSorted !== newSorted) {
                Settings.updateWallpaperFolderImages(tempFiles);
                root.imageFiles = Settings.wallpaperFolderImages;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerHighest
        radius: 12
        border.width: 1
        border.color: Qt.darker(Theme.outline)
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: root.padding
        cellWidth: root.cellWidth + root.spacing
        cellHeight: root.cellHeight + root.spacing
        model: root.imageFiles
        cacheBuffer: 300
        clip: true

        delegate: Rectangle {
            id: imageCell
            width: root.cellWidth
            height: root.cellHeight
            color: Theme.surfaceContainer
            radius: 12
            clip: true
            readonly property bool isSelected: Utils.strip(Settings.wallpaperImage) == modelData

            required property string modelData
            required property int index

            CacheImage {
                id: img
                maxCacheSize: 256
                anchors.fill: parent
                imagePath: imageCell.modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            Rectangle {
                id: mask
                anchors.fill: img
                border.width: Utils.strip(Settings.wallpaperImage) == imageCell.modelData ? 2 : 0
                border.color: Theme.primary
                radius: 12
                clip: true
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: img
                maskSource: mask
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.width: imageCell.isSelected ? 2 : 0
                border.color: Theme.primary
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("Selected:", imageCell.modelData);
                    Settings.updateWallpaperImage("file://" + imageCell.modelData);
                }
            }
        }
    }

    Process {
        id: wallpaperProcess
        running: false
    }
}
