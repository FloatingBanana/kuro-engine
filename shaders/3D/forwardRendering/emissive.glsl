#pragma language glsl3
#pragma include "engine/shaders/incl_commonBuffers.glsl"

#ifdef VERTEX
in vec2 VertexTexCoords;
in vec3 VertexNormal;
out vec2 v_texCoords;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = uWorldMatrix * position;
    vec4 screen = uViewProjMatrix * worldPos;

    // Assigning outputs
    v_texCoords = VertexTexCoords;
    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (uIsCanvasActive ? -1 : 1);

    return screen;
}
#endif

#ifdef PIXEL
in vec2 v_texCoords;
uniform sampler2D u_diffuseTexture;
uniform float u_strenght;

vec4 effect(EFFECTARGS) {
    return texture(u_diffuseTexture, v_texCoords) * u_strenght;
}
#endif