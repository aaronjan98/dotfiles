#version 440
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
    vec3 colourA;
    vec3 colourB;
    vec3 colourC;
    vec3 colourD;
    float boundary0;
    float boundary1;
    float boundary2;
    float transitionWidth;
    float fillAlpha;
};
void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
