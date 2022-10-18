attribute vec2 VertexTexCoords;
attribute vec3 VertexNormal;

varying vec3 v_normal;
varying vec3 v_fragPos;
varying vec2 v_texCoords;

uniform mat4 u_world;
uniform mat3 u_invTranspWorld;
uniform mat4 u_viewProj;
uniform mat4 u_lightViewProj;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;

    v_texCoords = VertexTexCoords;
    v_fragPos = worldPos.xyz;
    v_normal = u_invTranspWorld * VertexNormal;

    return u_viewProj * worldPos;
}