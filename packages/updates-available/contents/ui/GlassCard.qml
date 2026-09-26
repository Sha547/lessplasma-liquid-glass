// Frosted/liquid-glass card, rendered with real shaders: a Dual Kawase blur
// pyramid plus a Snell's-law refraction band at the edges, sampling the
// live desktop wallpaper item directly (not a polled screenshot).
//
// Pipeline adapted from jaxparrow07/liquidglass-kde-widgets (GPL-3.0), with
// attribution, and simplified to this pack's needs: a single fixed shape
// (no solid-color mode, no animated-wallpaper realtime toggle exposed) and
// the same external API as the old MultiEffect-based GlassCard.qml
// (cornerRadius / blurAmount / tintOpacity / tintColor), so every widget's
// main.qml needed zero changes to pick this up.
//
//   wallpaper item -> crop (extract widget region)
//     -> Dual Kawase downsample/upsample (blur pyramid)
//     -> liquidglass shader (SDF squircle + refraction + chroma + tint + specular)
//
// Falls back to a flat translucent rounded rect when the containment's
// wallpaper item isn't reachable (panels, plasmoidviewer).
import QtQuick
import org.kde.plasma.plasmoid

Item {
    id: glass

    // ---- external API (unchanged from the old MultiEffect card) ----
    property real cornerRadius: 20
    property real blurAmount: 1.0
    property real tintOpacity: 0.42
    property color tintColor: "#0d0d10"

    // ---- look, fixed per-card (not exposed in per-widget config) ----
    property real roundness: 4.5         // superellipse exponent; 2 = plain rounded rect
    property real refractThickness: 22   // edge band width, px
    property real refractIOR: 1.6
    property real refractScale: 40
    property real chromaStrength: 0.22
    property real specStrength: 0.6

    default property alias cardContent: contentHolder.data

    // ---- live wallpaper item lookup ----

    readonly property var wallpaperItem: {
        const c = Plasmoid.containment;
        if (!c) return null;
        const w = c.wallpaperGraphicsObject;
        if (!w) return null;
        return findRenderableSource(w);
    }

    readonly property bool active: wallpaperItem !== null
                                   && wallpaperItem.width > 0
                                   && wallpaperItem.height > 0

    function isLoader(n) { return n && n.sourceComponent !== undefined && n.item !== undefined; }
    // Pick the topmost sized item. ShaderEffectSource captures the whole
    // subtree, so descending into children is only needed when the outer
    // wrapper has no size yet (e.g. a Loader still resolving).
    function findRenderableSource(node) {
        if (!node) return null;
        if (isLoader(node)) return findRenderableSource(node.item);
        if (node.width > 0 && node.height > 0) return node;
        if (node.children && node.children.length > 0) {
            for (var i = 0; i < node.children.length; i++) {
                const inner = findRenderableSource(node.children[i]);
                if (inner) return inner;
            }
        }
        return null;
    }

    property real _offX: 0
    property real _offY: 0
    function updateGeometry() {
        if (!wallpaperItem) return;
        const p = glass.mapToItem(wallpaperItem, 0, 0);
        var moved = false;
        if (p.x !== _offX) { _offX = p.x; moved = true; }
        if (p.y !== _offY) { _offY = p.y; moved = true; }
        if (moved) { wallpaperTex.scheduleUpdate(); markDirty(); }
    }

    // ---- redraw gating: the blur pyramid only runs in short bursts after
    // something actually changes, so a static wallpaper doesn't force the
    // scene graph to re-blur every frame forever. ----
    property bool _dirtyBurst: false
    function markDirty() { _dirtyBurst = true; settleTimer.restart(); }
    Timer { id: settleTimer; interval: 250; onTriggered: glass._dirtyBurst = false }
    readonly property bool _chainLive: glass._blurActive && glass._dirtyBurst

    onWidthChanged: markDirty()
    onHeightChanged: markDirty()
    onWallpaperItemChanged: markDirty()
    onActiveChanged: markDirty()
    Component.onCompleted: { updateGeometry(); markDirty(); }

    // A widget's position can change without a signal we can bind to (an
    // ancestor moves, the containment relayouts). Poll slowly at rest, and
    // quickly for a moment after a move is detected so dragging still tracks.
    Timer {
        interval: glass._dirtyBurst ? 16 : 500
        repeat: true
        running: glass.active && glass.visible && glass.width > 0 && glass.height > 0
        onTriggered: glass.updateGeometry()
    }

    // ---- mouse tracking for the specular highlight ----
    property real _mouseU: -1
    property real _mouseV: -1
    property real _mouseFade: 0
    Behavior on _mouseFade { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: glass.specStrength > 0
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onPositionChanged: (mouse) => {
            glass._mouseU = mouse.x / Math.max(1, glass.width);
            glass._mouseV = mouse.y / Math.max(1, glass.height);
            glass._mouseFade = 1;
        }
        onEntered: glass._mouseFade = 1
        onExited: { glass._mouseFade = 0; glass._mouseU = -1; glass._mouseV = -1; }
    }

    // ---- wallpaper capture ----

    ShaderEffectSource {
        id: wallpaperTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass.wallpaperItem
        live: false
        hideSource: false
        recursive: false
        smooth: true
        mipmap: true
        textureMirroring: ShaderEffectSource.MirrorVertically
        onSourceItemChanged: scheduleUpdate()
    }

    readonly property vector2d _uvOff: glass.active
        ? Qt.vector2d(glass._offX / glass.wallpaperItem.width, glass._offY / glass.wallpaperItem.height)
        : Qt.vector2d(0, 0)
    readonly property vector2d _uvSc: glass.active
        ? Qt.vector2d(glass.width / glass.wallpaperItem.width, glass.height / glass.wallpaperItem.height)
        : Qt.vector2d(1, 1)

    readonly property real _widgetW: Math.max(1, glass.width)
    readonly property real _widgetH: Math.max(1, glass.height)
    readonly property bool _blurActive: glass.active && glass.blurAmount > 0

    // blurAmount (0..1, this pack's existing config knob) -> blur reach in
    // widget pixels, then -> Dual Kawase pyramid depth (1-5 levels).
    readonly property real _blurPx: glass.blurAmount * 26 + 4
    readonly property int _blurIters: {
        if (!_blurActive) return 0;
        var r = glass._blurPx;
        if (r <= 4) return 1;
        if (r <= 8) return 2;
        if (r <= 16) return 3;
        return Math.min(5, r <= 32 ? 4 : 5);
    }

    // ---- crop pass ----

    ShaderEffect {
        id: cropPass
        anchors.fill: parent
        visible: false
        fragmentShader: Qt.resolvedUrl("shaders/crop.frag.qsb")
        property variant source: wallpaperTex
        property vector2d uvOffset: glass._uvOff
        property vector2d uvScale: glass._uvSc
    }
    ShaderEffectSource {
        id: cropTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass._blurActive ? cropPass : null
        live: glass._chainLive
        hideSource: true
        smooth: true
    }

    // ---- Dual Kawase: downsample chain (up to 5 levels) ----

    ShaderEffect {
        id: down1
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_down.frag.qsb")
        property variant source: cropTex
        property vector2d halfpixel: Qt.vector2d(0.5 / glass._widgetW, 0.5 / glass._widgetH)
    }
    ShaderEffectSource {
        id: down1Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 1 ? down1 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.max(1, Math.round(glass._widgetW / 2)), Math.max(1, Math.round(glass._widgetH / 2)))
    }

    ShaderEffect {
        id: down2
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_down.frag.qsb")
        property variant source: down1Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down1Tex.textureSize.width), 0.5 / Math.max(1, down1Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: down2Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 2 ? down2 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.max(1, Math.round(glass._widgetW / 4)), Math.max(1, Math.round(glass._widgetH / 4)))
    }

    ShaderEffect {
        id: down3
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_down.frag.qsb")
        property variant source: down2Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down2Tex.textureSize.width), 0.5 / Math.max(1, down2Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: down3Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 3 ? down3 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.max(1, Math.round(glass._widgetW / 8)), Math.max(1, Math.round(glass._widgetH / 8)))
    }

    ShaderEffect {
        id: down4
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_down.frag.qsb")
        property variant source: down3Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down3Tex.textureSize.width), 0.5 / Math.max(1, down3Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: down4Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 4 ? down4 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.max(1, Math.round(glass._widgetW / 16)), Math.max(1, Math.round(glass._widgetH / 16)))
    }

    ShaderEffect {
        id: down5
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_down.frag.qsb")
        property variant source: down4Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down4Tex.textureSize.width), 0.5 / Math.max(1, down4Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: down5Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 5 ? down5 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.max(1, Math.round(glass._widgetW / 32)), Math.max(1, Math.round(glass._widgetH / 32)))
    }

    // ---- Dual Kawase: upsample chain (mirrors downsample) ----

    ShaderEffect {
        id: up5
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_up.frag.qsb")
        property variant source: down5Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down4Tex.textureSize.width), 0.5 / Math.max(1, down4Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: up5Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 5 ? up5 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: down4Tex.textureSize
    }

    ShaderEffect {
        id: up4
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_up.frag.qsb")
        property variant source: glass._blurIters >= 5 ? up5Tex : down4Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down3Tex.textureSize.width), 0.5 / Math.max(1, down3Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: up4Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 4 ? up4 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: down3Tex.textureSize
    }

    ShaderEffect {
        id: up3
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_up.frag.qsb")
        property variant source: glass._blurIters >= 4 ? up4Tex : down3Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down2Tex.textureSize.width), 0.5 / Math.max(1, down2Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: up3Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 3 ? up3 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: down2Tex.textureSize
    }

    ShaderEffect {
        id: up2
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_up.frag.qsb")
        property variant source: glass._blurIters >= 3 ? up3Tex : down2Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, down1Tex.textureSize.width), 0.5 / Math.max(1, down1Tex.textureSize.height))
    }
    ShaderEffectSource {
        id: up2Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive && glass._blurIters >= 2 ? up2 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: down1Tex.textureSize
    }

    ShaderEffect {
        id: up1
        anchors.fill: parent; visible: false
        fragmentShader: Qt.resolvedUrl("shaders/kawase_up.frag.qsb")
        property variant source: glass._blurIters >= 2 ? up2Tex : down1Tex
        property vector2d halfpixel: Qt.vector2d(0.5 / glass._widgetW, 0.5 / glass._widgetH)
    }
    ShaderEffectSource {
        id: up1Tex; anchors.fill: parent; opacity: 0
        sourceItem: glass._blurActive ? up1 : null
        live: glass._chainLive; hideSource: true; smooth: true
        textureSize: Qt.size(Math.round(glass._widgetW), Math.round(glass._widgetH))
    }

    // ---- glass shader: SDF squircle + refraction + chroma + tint + specular ----

    ShaderEffect {
        id: glassShader
        anchors.fill: parent
        visible: glass.active
        fragmentShader: Qt.resolvedUrl("shaders/liquidglass.frag.qsb")

        property variant backdrop: glass._blurActive ? up1Tex : wallpaperTex
        property size size: Qt.size(glass._widgetW, glass._widgetH)
        property real radius: glass.cornerRadius
        property real roundness: glass.roundness
        property real refractThickness: glass.refractThickness
        property real refractIOR: glass.refractIOR
        property real refractScale: glass.refractScale
        property real chromaStrength: glass.chromaStrength
        property vector4d tint: Qt.vector4d(glass.tintColor.r, glass.tintColor.g, glass.tintColor.b, glass.tintOpacity)
        property vector4d tintBottom: Qt.vector4d(0, 0, 0, 0)

        property vector2d mousePos: Qt.vector2d(glass._mouseU, glass._mouseV)
        property real mouseFade: glass._mouseFade
        property real specStrength: glass.specStrength
        property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)

        property vector2d uvOffset: glass._blurActive ? Qt.vector2d(0, 0) : glass._uvOff
        property vector2d uvScale: glass._blurActive ? Qt.vector2d(1, 1) : glass._uvSc
    }

    // ---- fallback: panels / plasmoidviewer where there's no wallpaper item ----

    Rectangle {
        anchors.fill: parent
        visible: !glass.active
        color: glass.tintColor
        opacity: Math.max(glass.tintOpacity, 0.55)
        radius: glass.cornerRadius
    }

    Item {
        id: contentHolder
        anchors.fill: parent
        clip: true
    }
}
