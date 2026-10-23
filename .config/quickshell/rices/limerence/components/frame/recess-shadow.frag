#version 440

// Recess shadow as a signed-distance-field gradient — drawn as an INSET along the inner
// edge of the rounded content hole. Darkest right at the content-frame edge, fading
// INWARD to nothing over `span` px. Anchoring to the hole's inner edge (a clean uniform
// rounded rect) makes the shadow identical on all four sides, independent of how wide the
// frame trim is outside — so the thin right/bottom trim looks the same as the thick
// top/left, and it always fades fully to nothing instead of being cut off. Outside the
// hole (the flat frame fill) the alpha is 0.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;   // ShaderEffect item size, px
    vec4 holeRect;     // content hole: x, y, w, h (item coords)
    float radius;      // hole corner radius
    float span;        // how far (px) the shadow reaches inward from the content edge
    float peakFrac;    // falloff exponent: higher = mass skewed toward the content edge
    float maxAlpha;    // peak shadow alpha (right at the content edge)
};

// Signed distance to a rounded box centred at the origin, half-size b, corner r.
// Negative inside the box, positive outside.
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 center = holeRect.xy + holeRect.zw * 0.5;

    // Distance from the content-frame edge, outward into the frame fill (>0 in the fill).
    float d = sdRoundedBox(px - center, holeRect.zw * 0.5, radius);

    float a = 0.0;
    if (d > 0.0 && span > 0.0) {
        // Outset over a FIXED span, sized LARGER than the thick frame edges on purpose.
        // Darkest right at the content-frame edge (d=0), fading OUTWARD. Because span
        // overshoots the frame, the shadow is still fading when it reaches the screen edge
        // and "bleeds off" rather than ending inside the frame (no floating band). On the
        // thick top/left (~53px) it's down to near-nothing by the edge; on the thin
        // right/bottom trim the overshoot means the visible near-edge part still shows
        // instead of collapsing into an invisible sliver. peakFrac skews the mass inward.
        float f = clamp(d / span, 0.0, 1.0);
        a = maxAlpha * pow(1.0 - f, peakFrac);
    }

    // Premultiplied black.
    fragColor = vec4(0.0, 0.0, 0.0, a) * qt_Opacity;
}
