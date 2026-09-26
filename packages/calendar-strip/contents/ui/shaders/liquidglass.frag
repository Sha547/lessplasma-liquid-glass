#version 440

// Liquid-glass fragment shader -- Snell-on-a-dome refraction + corner specular.
//
// Adapted from jaxparrow07/liquidglass-kde-widgets (GPL-3.0), which this
// pack borrows its glass rendering pipeline from with attribution. That
// project in turn ported the refraction core from iyinchao/liquid-glass-studio.
//
// Key ideas:
//   * Edge refraction uses Snell's law through a dome-shaped bevel:
//         sinThetaI = (1 - t)^2      where t = 0..1 across the edge band
//         thetaT    = asin(sinThetaI / IOR)
//         mag       = tan(thetaI - thetaT)   // lateral shift of the refracted ray
//   * SDF gradient is kept UNNORMALIZED and its magnitude is reused as a
//     corner-AA gate.
//   * Chromatic dispersion: R/B sampled at an extra offset along the
//     refraction direction, scaled by how deep we are in the edge band.
//   * Free-following specular: on hover, a primary highlight follows the
//     cursor with exponential arc-length taper; a secondary highlight
//     appears at the antipodal point at ~65% intensity.
//
// qt_TexCoord0 is widget-local UV (0..1).
// uvOffset/uvScale map widget UV -> wallpaper UV.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  size;              // widget size in px
    float radius;            // corner radius in px
    float roundness;         // superellipse exponent; 2 = circle, 5 ~= iOS squircle
    float refractThickness;  // edge band width in px
    float refractIOR;
    float refractScale;
    float chromaStrength;    // 0..1 chromatic aberration
    vec4  tint;
    vec4  tintBottom;
    vec2  uvOffset;
    vec2  uvScale;
    vec2  mousePos;          // widget-local UV (0..1); (-1,-1) = no mouse
    float mouseFade;         // 0..1 hover fade
    float specStrength;      // 0..1 intensity
    vec4  overlayDarken;     // rgb = target blend color, a = band height (0 = off)
};

layout(binding = 1) uniform sampler2D backdrop;

// --- Shape SDF: superellipse-cornered rounded rect (squircle) ---
vec3 sceneSDFAndNormal(vec2 p) {
    vec2 b = size * 0.5;
    float n = max(roundness, 2.0);
    float r = clamp(radius, 0.0, min(b.x, b.y));

    vec2 q = abs(p) - b + vec2(r);
    float qx = max(q.x, 0.0);
    float qy = max(q.y, 0.0);

    float d;
    vec2 nrm;

    if (qx <= 0.0 && qy <= 0.0) {
        d = max(q.x, q.y) - r;
        nrm = q.x >= q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    } else if (qx == 0.0) {
        d = qy - r;
        nrm = vec2(0.0, 1.0);
    } else if (qy == 0.0) {
        d = qx - r;
        nrm = vec2(1.0, 0.0);
    } else {
        float qxn = pow(qx, n);
        float qyn = pow(qy, n);
        float arc = pow(qxn + qyn, 1.0 / n);
        float gx = pow(qx / arc, n - 1.0);
        float gy = pow(qy / arc, n - 1.0);
        float gradLen = sqrt(gx*gx + gy*gy);
        d   = (arc - r) / max(gradLen, 1e-3);
        nrm = vec2(gx, gy) / max(gradLen, 1e-3);
    }

    nrm *= sign(p + vec2(1e-20));
    return vec3(d, nrm);
}

float sceneSDF(vec2 p) {
    return sceneSDFAndNormal(p).x;
}

vec3 sampleBackdrop(vec2 localUV) {
    vec2 wpUV = clamp(uvOffset + localUV * uvScale, vec2(0.0), vec2(1.0));
    return texture(backdrop, wpUV).rgb;
}

vec3 cornerSpec(vec2 p, float depthPx) {
    if (specStrength <= 0.0) return vec3(0.0);

    const float MAX_STROKE_PX = 3.0;
    const float FEATHER_PX    = 2.0;
    const float SECONDARY_INT = 0.65;

    vec2 b = size * 0.5;

    vec2 restLight = vec2(-b.x, b.y) * 1.2;
    bool hovering  = mouseFade > 0.0 && mousePos.x >= 0.0 && mousePos.y >= 0.0;
    vec2 cursorPx  = (mousePos - vec2(0.5)) * size;
    vec2 lightPx   = hovering ? mix(restLight, cursorPx, mouseFade) : restLight;

    vec2 antiLight = -lightPx;

    float taper = max(size.x, size.y) * 0.7;
    float primaryAtt   = exp(-distance(p, lightPx)   / taper);
    float secondaryAtt = exp(-distance(p, antiLight)  / taper) * SECONDARY_INT;

    float tPx = max(primaryAtt, secondaryAtt) * MAX_STROKE_PX;
    float stroke = 1.0 - smoothstep(tPx - FEATHER_PX, tPx, depthPx);

    float I = stroke * specStrength * 0.55;
    return vec3(1.0, 0.98, 0.94) * I;
}

vec3 edgeSpec(vec2 ndir, float depthPx) {
    if (specStrength <= 0.0) return vec3(0.0);

    float lip = 1.0 - smoothstep(0.0, 3.0, max(depthPx, 0.0));
    vec2 lightDir = normalize(vec2(-0.45, 0.90));
    float facing = 0.35 + 0.65 * clamp(dot(ndir, lightDir) * 0.5 + 0.5, 0.0, 1.0);
    float I = lip * facing * specStrength * 0.10;
    return vec3(1.0, 0.98, 0.94) * I;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p  = (uv - vec2(0.5)) * size;
    vec3 dn = sceneSDFAndNormal(p);
    float d = dn.x;
    vec2 ndir = dn.yz;

    if (d > 1.5) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 col;
    float depthPx = -d;

    bool canRefract = refractThickness > 0.0;

    vec3 tintColor = mix(tint.rgb, tintBottom.rgb, tintBottom.a > 0.0 ? uv.y : 0.0);
    float tintAlpha = tint.a;

    if (!canRefract || depthPx >= refractThickness) {
        col = sampleBackdrop(uv);
        col = mix(col, tintColor, tintAlpha);
    } else {
        float t = clamp(depthPx / refractThickness, 0.0, 1.0);
        float sinThetaI = (1.0 - t) * (1.0 - t);
        float thetaI = asin(clamp(sinThetaI, 0.0, 1.0));
        float sinThetaT = sinThetaI / refractIOR;
        float thetaT = asin(clamp(sinThetaT, 0.0, 1.0));
        float edgeMag = tan(thetaI - thetaT);

        vec2 displacePx = -ndir * edgeMag * refractScale;
        vec2 displaceUV = displacePx / size;

        float edgeWeight = 1.0 - t;
        float chromaPx = chromaStrength * refractThickness * 0.35 * edgeWeight;
        vec2 chromaUV = -ndir * chromaPx / size;

        col.r = sampleBackdrop(uv + displaceUV + chromaUV).r;
        col.g = sampleBackdrop(uv + displaceUV).g;
        col.b = sampleBackdrop(uv + displaceUV - chromaUV).b;

        col = mix(col, tintColor, tintAlpha);
    }

    if (overlayDarken.a > 0.0) {
        float darkenT = smoothstep(1.0 - overlayDarken.a, 1.0, uv.y);
        col = mix(col, overlayDarken.rgb, darkenT);
    }

    col += edgeSpec(ndir, depthPx);
    col += cornerSpec(p, depthPx);

    float mask = 1.0 - smoothstep(-0.5, 0.5, d);

    fragColor = vec4(col * mask, mask) * qt_Opacity;
}
