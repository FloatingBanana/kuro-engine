attribute vec3 VertexNormal;

uniform mat4 u_world;
uniform mat3 u_invTranspWorld;
uniform mat4 u_view;
uniform mat4 u_proj;

varying vec3 v_vertexNormal;
varying vec3 v_fragPos;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;

    v_vertexNormal = u_invTranspWorld * VertexNormal;
    v_fragPos = vec3(worldPos);

    return u_proj * u_view * worldPos;
}