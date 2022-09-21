attribute vec3 VertexNormal;

uniform mat4 u_world;
uniform mat3 u_invTranspWorld;
uniform mat4 u_view;
uniform mat4 u_proj;
uniform mat4 u_lightViewProj;

varying vec3 v_vertexNormal;
varying vec3 v_fragPos;
varying vec4 v_lightFragPos;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;

    v_fragPos = worldPos.xyz;
    v_vertexNormal = u_invTranspWorld * VertexNormal;
    v_lightFragPos = u_lightViewProj * vec4(v_fragPos, 1.0);

    return u_proj * u_view * worldPos;
}