#define MAX_LIGHTS 10

attribute vec2 VertexTexCoords;
attribute vec3 VertexNormal;
attribute vec3 VertexTangent;

varying vec3 v_fragPos;
varying vec2 v_texCoords;
varying mat3 v_tbnMatrix;
varying vec4 v_lightSpaceFragPos[MAX_LIGHTS];

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform bool u_isCanvasEnabled;
uniform mat4 u_lightMatrix[MAX_LIGHTS];

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;

    // Calculating the TBN matrix for normal mapping
    vec3 T = normalize(vec3(u_world * vec4(VertexTangent,   0.0)));
    vec3 N = normalize(vec3(u_world * vec4(VertexNormal,    0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);
    v_tbnMatrix = mat3(T, B, N);

    // Assigning outputs
    v_fragPos = worldPos.xyz;
    v_texCoords = VertexTexCoords;

    for (int i=0; i < MAX_LIGHTS; i++) {
        v_lightSpaceFragPos[i] = u_lightMatrix[i] * vec4(worldPos.xyz, 1.0);
    }

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    if (u_isCanvasEnabled)
        screen.y *= -1.0;

    return screen;
}