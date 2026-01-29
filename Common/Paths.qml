pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import QtCore

Singleton {
    id: root

    readonly property string home: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")
}
