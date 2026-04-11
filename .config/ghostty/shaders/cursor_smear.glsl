// Helper functions for the smear effect
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);
    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);
    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);
    return s * sqrt(d);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y);
    float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}

float ease(float x) {
    return pow(1.0 - x, 3.0);
}

#define TRAIL_COLOR vec3(1.0, 0.157, 0.0)
const float DURATION = 0.12; 

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 terminalColor = texture(iChannel0, fragCoord / iResolution.xy);

    vec2 curXY = iCurrentCursor.xy;
    vec2 curZW = iCurrentCursor.zw;
    vec2 prevXY = iPreviousCursor.xy;

    float vertexFactor = determineStartVertexFactor(curXY, prevXY);
    float invVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(curXY.x + curZW.x * vertexFactor, curXY.y - curZW.y);
    vec2 v1 = vec2(curXY.x + curZW.x * invVertexFactor, curXY.y);
    vec2 v2 = vec2(prevXY.x + curZW.x * invVertexFactor, prevXY.y);
    vec2 v3 = vec2(prevXY.x + curZW.x * vertexFactor, prevXY.y - curZW.y);

    float sdfCursor = getSdfRectangle(fragCoord, curXY + curZW * vec2(0.5, -0.5), curZW * 0.5);
    float sdfTrail = getSdfParallelogram(fragCoord, v0, v1, v2, v3);

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float easedProgress = ease(progress);
    float lineLength = distance(curXY, prevXY);

    // Trail only — cursor block is rendered natively by Ghostty.
    // 1-pixel margin ensures the trail never bleeds into the cursor cell.
    float trailActive = step(sdfTrail, 0.0) * step(1.0, sdfCursor) * step(sdfCursor, easedProgress * lineLength);

    fragColor = vec4(mix(terminalColor.rgb, TRAIL_COLOR, trailActive), terminalColor.a);
}
