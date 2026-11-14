#version 440

// Pass-through vertex shader matching kanata-droplet.frag so qt_TexCoord0 links on the
// OpenGL backend (same reason as recess-shadow.vert). The UBO must be byte-identical
// to the fragment's.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    vec2 center;
    float radiusX;
    float radiusY;
    vec3 baseColour;
    float coreAlpha;
    float rimAlpha;
    float crescentAlpha;
};

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
