attribute vec2 VertexTexCoords;
attribute vec3 VertexNormal;
attribute vec3 VertexTangent;
attribute vec3 VertexBitangent;

varying vec3 v_fragPos;
varying vec2 v_texCoords;
varying mat3 v_tbnMatrix;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform mat4 u_lightViewProj;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;

    v_texCoords = VertexTexCoords;
    v_fragPos = worldPos.xyz;

    vec3 T = normalize(vec3(u_world * vec4(VertexTangent,   0.0)));
    vec3 N = normalize(vec3(u_world * vec4(VertexNormal,    0.0)));
    // vec3 B = normalize(vec3(u_world * vec4(VertexBitangent, 0.0)));

    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);

    v_tbnMatrix = mat3(T, B, N);

    return u_viewProj * worldPos;
}