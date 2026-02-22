import QtQuick
import QtQuick.Shapes
import qs.Common

Item {
    id: root

    // Size of the curve (width = height = radius for a perfect quarter circle)
    property int curveRadius: 25
    property color color: "#1e1e2e"

    // Flip controls to place the curve in any of the 4 corners
    property bool flipX: false
    property bool flipY: false

    transform: Scale {
        xScale: root.flipX ? -1 : 1
        yScale: root.flipY ? -1 : 1
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            fillColor: root.color

            // START at bottom-left corner (0, curveRadius)
            startX: 0
            startY: root.curveRadius

            // STEP 1: Draw the curved arc
            // From (0, curveRadius) → (curveRadius, 0)
            // Clockwise direction = curves INWARD (concave)
            PathArc {
                x: root.curveRadius
                y: 0
                radiusX: root.curveRadius
                radiusY: root.curveRadius
                direction: PathArc.Clockwise
            }

            // STEP 2: Straight line to top-left corner (0, 0)
            PathLine {
                x: 0
                y: 0
            }

            // STEP 3: Straight line back to start (0, curveRadius)
            // Closes the triangle
            PathLine {
                x: 0
                y: root.curveRadius
            }
        }
    }
}
