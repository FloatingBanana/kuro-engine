#pragma language glsl3

in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;

out vec3 v_fragPos;
out vec4 v_screenPos;
out vec2 v_texCoords;
out mat3 v_tbnMatrix;
out vec4 v_lightSpaceFragPos;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform bool u_isCanvasEnabled;
uniform mat4 u_lightMatrix;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;

    // Calculating the TBN matrix for normal mapping
    vec3 T = normalize(vec3(u_world * vec4(VertexTangent,   0.0)));
    vec3 N = normalize(vec3(u_world * vec4(VertexNormal,    0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);
    v_tbnMatrix = mat3(T, B, N);

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    if (u_isCanvasEnabled)
        screen.y *= -1.0;

    // Assigning outputs
    v_fragPos = worldPos.xyz;
    v_screenPos = screen;
    v_texCoords = VertexTexCoords;
    v_lightSpaceFragPos = u_lightMatrix * vec4(worldPos.xyz, 1.0);

    return screen;
}