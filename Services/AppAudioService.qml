pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property int totalNodeCount: (Pipewire.nodes?.values || []).length
    property var resolvedIcons: ({})

    signal applicationVolumeChanged
    signal applicationMuteChanged
    signal streamsChanged

    Component.onCompleted: {
        if (Pipewire.nodes) {
            Pipewire.nodes.valuesChanged.connect(() => {
                streamsChanged();
            });
        }
    }

    function isValidNode(node) {
        return node && node.ready;
    }

    function isValidAudioNode(node) {
        return isValidNode(node) && node.audio;
    }

    function isValidStreamNode(node) {
        return isValidAudioNode(node) && node.isStream !== undefined;
    }

    readonly property var applicationStreams: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidStreamNode(node))
            return false;
        return node.isStream && node.isSink;
    })

    readonly property var applicationInputStreams: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidStreamNode(node))
            return false;

        return node.isStream && !node.isSink;
    })

    readonly property var outputDevices: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidNode(node))
            return false;

        return !node.isStream && node.isSink;
    })

    readonly property var inputDevices: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidNode(node))
            return false;

        return !node.isStream && !node.isSink;
    })

    function getApplicationName(node, cb) {
        if (!isValidNode(node)) {
            return "Unknown Application";
        }

        const props = node.properties || {};
        const desc = node.description || {};

        if (props["pipewire.access.portal.app_id"]) {
              let appId = props["pipewire.access.portal.app_id"];
              cb(appId);
              return;
          }


        let name = props["application.name"]  || props["media.title"]  || props["media.name"];

        if (!name && props["application.id"]) {
            let id = props["application.id"].split('.').pop();
            name = id.charAt(0).toUpperCase() + id.slice(1);
        }

        if (!name && props["application.process.binary"]) {
            name = props["application.process.binary"].split('/').pop();
        }

        if (name.includes("electron") || name.includes("chromium")) {
            name = "chromium";
            resolveAppName(node, function (name) {
                name = name;
            });
        }

        if (!name && desc) {
            name = desc;
        }

        cb(name);
    }

    function resolveAppName(node, callback) {
        let props = node.properties;
        // --- Native apps: /proc works fine ---
        let procId = props["application.process.id"]?.toString();
        if (!procId) {
            if (callback) callback("unknown");
            return;
        }

        if (root.resolvedIcons[procId]) {
            if (callback) callback(root.resolvedIcons[procId]);
            return;
        }

        let proc = resolverComponent.createObject(root, {
            "command": ["cat", "/proc/" + procId + "/environ"],
            "pid": procId,
            "callback": callback
        });
        proc.running = true;
    }

    Component {
        id: resolverComponent
        Process {
            id: procResolver
            property var callback: null
            property string result: ""
            property string pid

            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    result += data;
                }
            }

            onExited: (exitCode, exitStatus) => {
                let appName = "unknown";
                if (exitCode === 0 && result.length > 0) {
                    let data = result.trim().split("\0");
                    for (let part of data) {
                        if (part.startsWith("CHROME_DESKTOP=")) {
                            appName = part.split("=").slice(1).join("=");
                            appName = appName.replace(".desktop", "");
                            break;
                        }
                        if (part.startsWith("GDK_PROGRAM_CLASS=")) {
                            appName = part.split("=").slice(1).join("=");
                            break;
                        }
                    }
                    let newCache = root.resolvedIcons;
                    newCache[procResolver.pid] = appName;
                    root.resolvedIcons = newCache;



                    if (procResolver.callback && typeof procResolver.callback === "function") {
                        procResolver.callback(appName);
                    }

                    procResolver.destroy();
                }
            }
        }
    }

    function getApplicationVolumeIcon(node) {
        if (!node || !node.audio) {
            return "volume_off";
        }

        if (node.ready === false) {
            return "volume_off";
        }

        // Check muted first
        if (node.audio.muted) {
            return "volume_off";
        }

        // Convert 0.0-1.0 to 0-100
        let volume = (node.audio.volume ?? 0) * 100;

        if (volume > 60) {
            return "volume_up";
        } else if (volume > 0) {
            return "volume_down";
        } else {
            return "volume_off";
        }
    }

    function setApplicationVolume(node, percentage) {
        if (!isValidNode(node)) {
            return "Not a Valid node";
        }

        const clampedVolume = Math.max(0, Math.min(100, percentage));
        const volumeValue = clampedVolume / 100;
        node.audio.volume = volumeValue;
        root.applicationVolumeChanged();
        return `Volume set to ${clampedVolume}%`;
    }

    function toggleApplicationMute(node) {
        if (!isValidNode(node)) {
            return "Not a valid audio node";
        }
        node.audio.muted = !node.audio.muted;
        root.applicationMuteChanged();
        return node.audio.muted ? "Application muted" : "Application unmuted";
    }

    function setApplicationInputVolume(node, percentage) {
        if (!isValidAudioNode(node)) {
            return "Not a valid audio node";
        }
        const clampedVolume = Math.max(0, Math.min(100, percentage));
        node.audio.volume = clampedVolume / 100;
        root.applicationVolumeChanged();
        return `Input volume set to ${clampedVolume}%`;
    }

    function toggleApplicationInputMute(node) {
        if (!isValidAudioNode(node)) {
            return "Not a valid audio node";
        }
        node.audio.muted = !node.audio.muted;
        root.applicationMuteChanged();
        return node.audio.muted ? "Application input muted" : "Application input unmuted";
    }

    function routeStreamToOutput(streamNode, targetSinkNode) {
        if (!streamNode || !targetSinkNode) {
            return "Invalid stream or target device";
        }
        if (!streamNode.isStream || !streamNode.isSink) {
            return "Not an output stream";
        }
        if (targetSinkNode.isStream || !targetSinkNode.isSink) {
            return "Not a valid output device";
        }

        try {
            const streamId = streamNode.id;
            const sinkId = targetSinkNode.id;

            if (!streamId || !sinkId) {
                return "Invalid stream or sink ID";
            }

            const connectCmd = ["pw-link", streamId.toString(), sinkId.toString()];

            const connectProcess = connectProcessComponent.createObject(root, {
                streamId: streamId,
                sinkId: sinkId,
                deviceName: targetSinkNode.description || targetSinkNode.name,
                callback: function () {
                    root.applicationVolumeChanged();
                }
            });

            return "Routing stream...";
        } catch (e) {
            return "Failed to route stream: " + e;
        }
    }

    Component {
        id: connectProcessComponent
        Process {
            property int streamId
            property int sinkId
            property string deviceName
            property var callback

            command: ["pw-link", streamId.toString(), sinkId.toString()]

            Component.onCompleted: {
                running = true;
            }

            onExited: function (exitCode) {
                if (exitCode === 0) {
                    if (callback)
                        callback();
                } else {
                    if (typeof LoggingService !== 'undefined') {
                        LoggingService.debug("ApplicationAudioService", "Primary connection failed, trying alternative", {
                            exitCode: exitCode,
                            streamId: streamId,
                            sinkId: sinkId
                        });
                    }
                    const altProcess = connectProcessAltComponent.createObject(root, {
                        streamId: streamId,
                        sinkId: sinkId,
                        deviceName: deviceName,
                        callback: callback
                    });
                    if (!altProcess) {
                        if (typeof LoggingService !== 'undefined') {
                            LoggingService.error("ApplicationAudioService", "Failed to create alternative connection process");
                        }
                    }
                }
                destroy();
            }
        }
    }

    Component {
        id: connectProcessAltComponent
        Process {
            property int streamId
            property int sinkId
            property string deviceName
            property var callback

            command: ["pw-link", streamId.toString() + ":output_FL", sinkId.toString() + ":input_FL"]

            Component.onCompleted: {
                running = true;
            }

            onExited: function (exitCode) {
                if (exitCode === 0 && callback) {
                    callback();
                } else {
                    if (typeof LoggingService !== 'undefined') {
                        LoggingService.warn("ApplicationAudioService", "Alternative connection process failed", {
                            exitCode: exitCode,
                            streamId: streamId,
                            sinkId: sinkId
                        });
                    }
                }
                destroy();
            }
        }
    }

    function routeStreamToInput(streamNode, targetSourceNode) {
        if (!streamNode || !targetSourceNode) {
            return "Invalid stream or target device";
        }
        if (!streamNode.isStream || streamNode.isSink) {
            return "Not an input stream";
        }
        if (targetSourceNode.isStream || targetSourceNode.isSink) {
            return "Not a valid input device";
        }

        try {
            const streamId = streamNode.id;
            const sourceId = targetSourceNode.id;

            if (!streamId || !sourceId) {
                return "Invalid stream or source ID";
            }

            const connectCmd = ["pw-link", sourceId.toString(), streamId.toString()];

            const connectProcess = connectInputProcessComponent.createObject(root, {
                streamId: streamId,
                sourceId: sourceId,
                deviceName: targetSourceNode.description || targetSourceNode.name,
                callback: function () {
                    root.applicationVolumeChanged();
                }
            });

            return "Routing input stream...";
        } catch (e) {
            return "Failed to route stream: " + e;
        }
    }

    Component {
        id: connectInputProcessComponent
        Process {
            property int streamId
            property int sourceId
            property string deviceName
            property var callback

            command: ["pw-link", sourceId.toString(), streamId.toString()]

            Component.onCompleted: {
                running = true;
            }

            onExited: function (exitCode) {
                if (exitCode === 0) {
                    if (callback)
                        callback();
                } else {
                    const altProcess = connectInputProcessAltComponent.createObject(root, {
                        streamId: streamId,
                        sourceId: sourceId,
                        deviceName: deviceName,
                        callback: callback
                    });
                }
                destroy();
            }
        }
    }

    Component {
        id: connectInputProcessAltComponent
        Process {
            property int streamId
            property int sourceId
            property string deviceName
            property var callback

            command: ["pw-link", sourceId.toString() + ":output_FL", streamId.toString() + ":input_FL"]

            Component.onCompleted: {
                running = true;
            }

            onExited: function (exitCode) {
                if (exitCode === 0 && callback) {
                    if (typeof callback === 'function') {
                        callback();
                    }
                } else {
                    if (typeof LoggingService !== 'undefined') {
                        LoggingService.warn("ApplicationAudioService", "Alternative input connection process failed", {
                            exitCode: exitCode,
                            streamId: streamId,
                            sourceId: sourceId
                        });
                    }
                }
                Qt.callLater(() => {
                    destroy();
                });
            }
        }
    }

    function getCurrentOutputDevice(streamNode) {
        if (!streamNode || !streamNode.isStream || !streamNode.isSink) {
            return null;
        }

        return AudioService.sink;
    }

    function getCurrentInputDevice(streamNode) {
        if (!streamNode || !streamNode.isStream || streamNode.isSink) {
            return null;
        }

        return AudioService.source;
    }

    function getTrackableNodes() {
        if (!Pipewire.nodes?.values)
            return [];
        const nodes = [];
        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i];
            if (!node)
                continue;

            if (node.ready && node.audio) {
                try {
                    if (node.properties !== undefined && node.name !== undefined) {
                        nodes.push(node);
                    }
                } catch (e) {}
            }
        }
        return nodes;
    }

    PwObjectTracker {
        objects: Pipewire.nodes?.values ?? []
    }

    function debugAllNodes() {
        if (!Pipewire.ready || !Pipewire.nodes?.values) {
            return;
        }
    }
}
