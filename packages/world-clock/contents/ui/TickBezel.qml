// Dashed tick ring traced along a rounded-rect boundary, like a watch bezel.
// Static per size/radius, so it only repaints on resize, not per tick of the clock.
import QtQuick

Canvas {
    id: bezel

    property real cornerRadius: 20
    property real inset: 8
    property int tickCount: 48
    property int majorEvery: 4
    property real tickLength: 6
    property real tickWidthMajor: 2
    property real tickWidthMinor: 1
    property real tickOpacity: 0.5

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onInsetChanged: requestPaint()
    onTickCountChanged: requestPaint()

    // Point + outward normal at arc-length fraction t (0..1) around a w x h
    // rounded rect of corner radius r, walking clockwise from the top edge.
    function pointOnRoundedRect(t, w, h, r) {
        var straightH = w - 2 * r;
        var straightV = h - 2 * r;
        var arc = (Math.PI / 2) * r;

        var segments = [
            { len: straightH, type: "line",
              start: { x: r, y: 0 }, dir: { x: 1, y: 0 }, normal: { x: 0, y: -1 } },
            { len: arc, type: "arc",
              cx: w - r, cy: r, startAngle: -Math.PI / 2, sweep: Math.PI / 2 },
            { len: straightV, type: "line",
              start: { x: w, y: r }, dir: { x: 0, y: 1 }, normal: { x: 1, y: 0 } },
            { len: arc, type: "arc",
              cx: w - r, cy: h - r, startAngle: 0, sweep: Math.PI / 2 },
            { len: straightH, type: "line",
              start: { x: w - r, y: h }, dir: { x: -1, y: 0 }, normal: { x: 0, y: 1 } },
            { len: arc, type: "arc",
              cx: r, cy: h - r, startAngle: Math.PI / 2, sweep: Math.PI / 2 },
            { len: straightV, type: "line",
              start: { x: 0, y: h - r }, dir: { x: 0, y: -1 }, normal: { x: -1, y: 0 } },
            { len: arc, type: "arc",
              cx: r, cy: r, startAngle: Math.PI, sweep: Math.PI / 2 },
        ];

        var perim = 0;
        for (var i = 0; i < segments.length; i++) perim += segments[i].len;
        var d = t * perim;

        for (var s = 0; s < segments.length; s++) {
            var seg = segments[s];
            if (d <= seg.len || s === segments.length - 1) {
                var local = Math.max(0, Math.min(seg.len, d));
                if (seg.type === "line") {
                    return {
                        x: seg.start.x + seg.dir.x * local,
                        y: seg.start.y + seg.dir.y * local,
                        nx: seg.normal.x,
                        ny: seg.normal.y
                    };
                }
                var angle = seg.startAngle + seg.sweep * (seg.len > 0 ? local / seg.len : 0);
                var nx = Math.cos(angle);
                var ny = Math.sin(angle);
                return { x: seg.cx + nx * r, y: seg.cy + ny * r, nx: nx, ny: ny };
            }
            d -= seg.len;
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var w = width - inset * 2;
        var h = height - inset * 2;
        var r = Math.min(cornerRadius, Math.min(w, h) / 2);
        if (w <= 0 || h <= 0 || tickCount <= 0) return;

        for (var i = 0; i < tickCount; i++) {
            var p = pointOnRoundedRect(i / tickCount, w, h, r);
            var major = (i % majorEvery === 0);
            var len = major ? tickLength : tickLength * 0.55;
            var alpha = major ? tickOpacity : tickOpacity * 0.55;

            var x = inset + p.x;
            var y = inset + p.y;

            ctx.strokeStyle = Qt.rgba(1, 1, 1, alpha);
            ctx.lineWidth = major ? tickWidthMajor : tickWidthMinor;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x - p.nx * len, y - p.ny * len);
            ctx.stroke();
        }
    }
}
