// Circular progress ring drawn on a Canvas: a plain track circle plus a
// colored arc for `progress`. Reused (copied per package, same rule as
// GlassCard) by any widget that shows a fraction as a ring.
import QtQuick

Canvas {
    id: arc

    property real progress: 0.5 // 0..1
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)
    property color progressColor: "#34C759"
    property real strokeWidth: 8
    property real startAngleDeg: -90 // 12 o'clock
    property bool clockwise: true

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onProgressColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var cx = width / 2, cy = height / 2;
        var r = Math.min(width, height) / 2 - strokeWidth / 2 - 1;
        if (r <= 0) return;

        ctx.lineCap = "round";

        ctx.strokeStyle = trackColor;
        ctx.lineWidth = strokeWidth;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
        ctx.stroke();

        var p = Math.max(0, Math.min(1, progress));
        if (p <= 0) return;

        var start = startAngleDeg * Math.PI / 180;
        var sweep = Math.PI * 2 * p * (clockwise ? 1 : -1);
        ctx.strokeStyle = progressColor;
        ctx.lineWidth = strokeWidth;
        ctx.beginPath();
        ctx.arc(cx, cy, r, start, start + sweep, !clockwise);
        ctx.stroke();
    }
}
