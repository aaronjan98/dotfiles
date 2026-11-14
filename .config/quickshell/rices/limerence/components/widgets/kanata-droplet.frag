#version 440

// Glassy "pill" mode indicator for the Kanata island (KanataIsland.qml). Draws a
// true rounded-box/capsule SDF -- the SAME sdRoundedBox technique as
// components/frame/recess-shadow.frag, just applied to a much smaller shape --
// instead of an ellipse. That matters for two concrete complaints an ellipse
// couldn't satisfy: (1) a capsule has FLAT sides, so when radiusY grows during
// the stretch animation the sides don't move at all and only the rounded caps
// travel further apart -- "stretch only in the direction it's moving", which an
// ellipse (every point depends on BOTH radii) can't do; (2) a flat-sided shape
// reads as crisp/defined where a continuously-curved oval reads as soft/blurry
// even with identical antialiasing width, because there's no straight edge for
// the eye to lock onto.
//
// A texture-sampling "lens" version of this (sampling the backdrop+letters
// through a ShaderEffectSource and boosting their own alpha, instead of
// painting a flat tint) was tried and REJECTED on sight, not just tuning: the
// letters visibly doubled/ghosted at the mask's antialiased edge (the dim
// original and the boosted sampled copy both partially visible there,
// slightly misaligned), the lens read as too bright/flat, and the rim read as
// a thick border once the interior was that bright too. Reverted back to this
// flat-tint version, which is the one actually liked.
//
// This build has no QtQuick.Effects/Qt5Compat.GraphicalEffects/QtQuick.Shapes
// (checked all three), so there is no blur/radial-gradient/arc primitive to
// reach for at the QML level -- this is the same reasoning that led to
// recess-shadow.frag being a shader instead of stacked Rectangles.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;     // ShaderEffect item size, px
    vec2 center;         // capsule centre, item-local px
    float radiusX;       // half-width, px -- CONSTANT; only radiusY moves (see above)
    float radiusY;       // half-height, px -- grows while moving, the "stretch"
    vec3 baseColour;     // active mode's tint (crossfaded, see KanataIsland.qml's droplet.tint)
    float coreAlpha;     // peak fill alpha at the capsule's centre -- the "see-through" knob
    float rimAlpha;      // edge-band alpha -- the meniscus definition
    float crescentAlpha; // reflection peak alpha
};

const float PI = 3.14159265359;

// Signed distance to a rounded box centred at the origin, half-size b, corner
// radius r (identical to recess-shadow.frag's copy). With b == (radiusX, radiusY)
// and r == min(radiusX, radiusY), this degenerates into exactly a capsule: the
// rounding consumes the full width/height on the short axis, leaving semicircular
// caps on the long axis and flat sides in between.
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 d = px - center;

    float capR = min(radiusX, radiusY);
    float dist = sdRoundedBox(d, vec2(radiusX, radiusY), capR);   // px, negative inside

    // The border sits INSET from the true geometric edge (rimOffset) -- see
    // the rim comment below. distRim == 0 at that inset line, which is now
    // the ONLY edge anything renders up to; nothing (fill, rim, or
    // reflection) extends past it.
    float rimOffset = 2.0;
    float distRim = dist + rimOffset;

    // Antialiased fill edge, a crisp ~1px regardless of size -- anchored to
    // the SAME inset line as the rim (distRim), not the true geometric edge.
    float aa = 1.0;
    float core = 1.0 - smoothstep(-aa, aa, distRim);

    // Rim: a SOLID stroke riding right at that same inset line. 0.6 is loose
    // enough to stay smooth on the capsule's curved caps (0.15 aliases into
    // visible jaggies there).
    float rimW = 2.2;
    float rimAA = 0.6;
    float rim = smoothstep(-rimW - rimAA, -rimW, distRim) - smoothstep(-rimAA, rimAA, distRim);
    rim = clamp(rim, 0.0, 1.0);

    // Core tint: vertical gradient (lighter near the top, truer hue near the
    // bottom) standing in for a radial light falloff -- cheap, but reads as
    // "round and lit" well enough at this size.
    float g = clamp(d.y / max(radiusY, 0.0001) * 0.5 + 0.5, 0.0, 1.0);
    vec3 lighter = mix(baseColour, vec3(1.0), 0.55);
    vec3 darker = baseColour * 0.85;
    vec3 coreColour = mix(lighter, darker, g);
    // A pale near-white wash reads as "soft highlight", not "solid border" --
    // the TRUE, more saturated hue (only a slight white lift, 0.65 -> 0.2)
    // is what a flat, solid-coloured outline actually looks like.
    vec3 rimColour = mix(baseColour, vec3(1.0), 0.2);

    // Reflection: a soft, subtle wash that HUGS the rim -- centred at the SAME
    // rimOffset as the border above, masked to the INNER side of the rim's
    // own outer edge only so its soft tail never bleeds across the one line
    // that has to stay crisp.
    float ang = atan(d.y, d.x);
    float angDist = PI - abs(ang);
    float angWeight = exp(-pow(angDist / radians(110.0), 2.0));
    float radWeight = exp(-pow(distRim / (capR * 0.22), 2.0));
    float crescentMask = 1.0 - smoothstep(-rimAA, rimAA, distRim);
    float crescent = clamp(angWeight * radWeight, 0.0, 1.0) * crescentMask;

    vec3 colour = mix(coreColour, rimColour, rim);
    colour = mix(colour, vec3(1.0), crescent);

    float alpha = core * coreAlpha + rim * rimAlpha * (1.0 - core) + crescent * crescentAlpha;
    alpha = clamp(alpha, 0.0, 1.0);

    // Premultiplied, matching recess-shadow's convention.
    fragColor = vec4(colour * alpha, alpha) * qt_Opacity;
}
