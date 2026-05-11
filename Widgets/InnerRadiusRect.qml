import QtQuick
import QtQuick.Shapes

Item {
    id: root

    // ========================================================
    // Standard Rectangle API (Drop-in Compatibility)
    // ========================================================

    // Fill color
    property alias color: shapePath.fillColor

    // Corner radius
    property real radius: 0

    // Border
    property QtObject border: QtObject {
        property color color: "transparent"
        property real width: 0
    }

    // Gradient (Note: Accepts ShapeGradients: LinearGradient, RadialGradient, ConicalGradient)
    // This is actually an upgrade over standard Rectangle, which only supports vertical LinearGradients.
    property alias gradient: shapePath.fillGradient

    // ========================================================
    // Custom API for Edge Anchoring & Inner Curves
    // ========================================================

    // Set to true for inner (scooped) corners, false for standard outer (convex) corners
    property bool concave: true

    // Set these to true depending on which screen edge the item is touching
    property bool anchorTop: false
    property bool anchorBottom: false
    property bool anchorLeft: false
    property bool anchorRight: false

    // ========================================================
    // Internal Logic
    // ========================================================

    // Prevent radius from exceeding half the width/height
    readonly property real r: Math.min(radius, width / 2, height / 2)

    // A corner only gets a curve if it's NOT touching an anchored edge
    readonly property bool cornerTL: !anchorTop && !anchorLeft
    readonly property bool cornerTR: !anchorTop && !anchorRight
    readonly property bool cornerBR: !anchorBottom && !anchorRight
    readonly property bool cornerBL: !anchorBottom && !anchorLeft

    Shape {
        anchors.fill: parent
        // Improves rendering performance in Quickshell
        asynchronous: true
        vendorExtensionsEnabled: true

        ShapePath {
            id: shapePath
            strokeColor: root.border.color
            strokeWidth: root.border.width
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            // 1. Start point (Top-Left)
            startX: 0
            startY: root.cornerTL ? root.r : 0

            // 2. Top-Left Corner
            PathArc {
                x: root.cornerTL ? root.r : 0
                y: 0
                radiusX: root.cornerTL ? root.r : 0
                radiusY: root.cornerTL ? root.r : 0
                // If concave, sweep clockwise (scoops outward). Otherwise, counterclockwise (standard round).
                direction: root.concave ? PathArc.Clockwise : PathArc.Counterclockwise
            }

            // 3. Top Edge
            PathLine {
                x: root.cornerTR ? root.width - root.r : root.width
                y: 0
            }

            // 4. Top-Right Corner
            PathArc {
                x: root.width
                y: root.cornerTR ? root.r : 0
                radiusX: root.cornerTR ? root.r : 0
                radiusY: root.cornerTR ? root.r : 0
                direction: root.concave ? PathArc.Clockwise : PathArc.Counterclockwise
            }

            // 5. Right Edge
            PathLine {
                x: root.width
                y: root.cornerBR ? root.height - root.r : root.height
            }

            // 6. Bottom-Right Corner
            PathArc {
                x: root.cornerBR ? root.width - root.r : root.width
                y: root.height
                radiusX: root.cornerBR ? root.r : 0
                radiusY: root.cornerBR ? root.r : 0
                direction: root.concave ? PathArc.Clockwise : PathArc.Counterclockwise
            }

            // 7. Bottom Edge
            PathLine {
                x: root.cornerBL ? root.r : 0
                y: root.height
            }

            // 8. Bottom-Left Corner
            PathArc {
                x: 0
                y: root.cornerBL ? root.height - root.r : root.height
                radiusX: root.cornerBL ? root.r : 0
                radiusY: root.cornerBL ? root.r : 0
                direction: root.concave ? PathArc.Clockwise : PathArc.Counterclockwise
            }

            // 9. Left Edge (Close shape back to startY)
            PathLine {
                x: 0
                y: root.cornerTL ? root.r : 0
            }
        }
    }
}
