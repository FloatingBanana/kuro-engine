#pragma language glsl3

#ifdef VERTEX
in vec2 VertexTexCoords;
in vec3 VertexNormal;
out vec2 v_texCoords;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform bool u_isCanvasEnabled;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;

    // Assigning outputs
    v_texCoords = VertexTexCoords;
    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (u_isCanvasEnabled ? -1 : 1);

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