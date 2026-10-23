#version 440

// Pass-through vertex shader matching recess-shadow.frag so qt_TexCoord0 links on the
// OpenGL backend (the default ShaderEffect vertex shader's varying location didn't
// match). The UBO must be byte-identical to the fragment's.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    vec4 holeRect;
    float radius;
    float span;
    float peakFrac;
    float maxAlpha;
};

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
