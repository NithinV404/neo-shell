import QtQuick

Canvas {
    id: root

    // exposed props
    property real lineWidth: 10
    property real waveHeight: 10
    property real frequency: 25
    property real startDegree: 0
    property real degree: 360 // This is the total arc length (360 = full circle)
    property real speed: 1
    property bool animate: true
    property real animationInterval: 16
    property color color: "#000"

    // NEW PROPERTIES: Add value and maxValue to control the progress
    property real value: 0.0      // e.g., 0.85 for 85%
    property real maxValue: 1.0   // e.g., 1.0 for normal, 1.1 or 1.5 for overdrive

    // ensure pixel density
    renderStrategy: Canvas.Cooperative
    antialiasing: true

    Timer {
        interval: root.animationInterval
        running: root.animate && root.visible
        repeat: true
        onTriggered: root.requestPaint()
    }

    onDegreeChanged: requestPaint()
    onColorChanged: requestPaint()
    onValueChanged: requestPaint()    // Repaint when volume changes
    onMaxValueChanged: requestPaint() // Repaint if overdrive is toggled

    onPaint: {
        let ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);

        const size = Math.min(width, height);
        const centerX = width / 2;
        const centerY = height / 2;

        const radius = size / 2 - root.waveHeight * 1.5;

        const phase = animate ? (Date.now() / 400) * speed : 0;

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";

        ctx.beginPath();

        function rad(n) {
            return (n * Math.PI) / 180;
        }

        // Calculate how many degrees of the circle to draw
        // Clamp the ratio between 0.0 and 1.0 so it doesn't over-draw if volume spikes
        const progressRatio = Math.max(0, Math.min(root.value / root.maxValue, 1.0));
        const drawDegree = root.degree * progressRatio;

        // Use Math.ceil to ensure smooth drawing right up to the edge
        const maxI = Math.ceil(drawDegree);

        for (let i = 0; i <= maxI; i++) {
            // Ensure the very last point drawn is exactly at the target degree
            const currentDegree = Math.min(i, drawDegree);
            const theta = rad(currentDegree + root.startDegree);

            const h = root.waveHeight * Math.sin(root.frequency * theta + phase);
            const r = radius + h;

            const x = centerX + r * Math.cos(theta);
            const y = centerY + r * Math.sin(theta);

            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }

        ctx.stroke();
    }
}
