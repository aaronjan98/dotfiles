#version 440

// Continuous per-mode colour backdrop for the WHOLE Kanata island (see
// KanataIsland.qml's trackBg ShaderEffect). Replaces an earlier plain-QML
// attempt: a Rectangle{clip:true; radius:...} containing a Column of flat
// per-word Rectangles plus small 2-stop-Gradient Rectangles for the seams.
// That attempt had two real bugs, not just a look that needed tuning:
// (1) Rectangle's clip does NOT actually mask children to the rounded
// radius in this Qt build -- children clipped to the full SQUARE bounding
// box instead, so the rounded top/bottom caps of the island rendered as
// empty/black domes, not filled with colour; (2) the colour blend between
// adjacent words was a literal QML Gradient painted over only `gap` real
// device pixels (a small integer, ~10-15px at this UI scale) -- too few
// pixels for the eye to read as a smooth fade rather than a hard seam.
// A hand SDF mask (the same sdRoundedBox technique as kanata-droplet.frag
// and recess-shadow.frag) sidesteps both: the mask is exact regardless of
// clip support, and the blend is a smoothstep computed at full fragment
// precision over a width this shader controls directly (transitionWidth),
// independent of the actual `gap` layout spacing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;       // this item's own size, px (== pill.width x totalTrackHeight)
    vec2 center;           // item-local px, == resolution / 2
    float radiusX;         // == resolution.x / 2 -- the island's own half-width
    float radiusY;         // == resolution.y / 2
    vec3 colourA;          // first mode's colour (Norm)
    vec3 colourB;          // second mode's colour (Cap)
    vec3 colourC;          // third mode's colour (Maj)
    vec3 colourD;          // fourth mode's colour (Exec)
    float boundary0;       // px, midpoint of the gap between word 0 and word 1
    float boundary1;       // px, midpoint of the gap between word 1 and word 2
    float boundary2;       // px, midpoint of the gap between word 2 and word 3
    float transitionWidth; // px, full width of the smoothstep fade at each boundary
    float fillAlpha;       // overall backdrop opacity (Appearance.modeZoneAlpha)
};

// Hardcoded to exactly 4 modes/3 boundaries, matching KanataCtl.modes
// (Norm/Cap/Maj/Exec) -- not worth generalising to N colours via array
// uniforms (std140 array padding) unless a 5th mode actually lands.
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 d = px - center;

    float capR = min(radiusX, radiusY);
    float dist = sdRoundedBox(d, vec2(radiusX, radiusY), capR);

    float aa = 1.0;
    float mask = 1.0 - smoothstep(-aa, aa, dist);

    float half_ = transitionWidth * 0.5;
    float t0 = smoothstep(boundary0 - half_, boundary0 + half_, px.y);
    float t1 = smoothstep(boundary1 - half_, boundary1 + half_, px.y);
    float t2 = smoothstep(boundary2 - half_, boundary2 + half_, px.y);
    vec3 colour = mix(mix(mix(colourA, colourB, t0), colourC, t1), colourD, t2);

    float alpha = mask * fillAlpha;
    fragColor = vec4(colour * alpha, alpha) * qt_Opacity;
}
