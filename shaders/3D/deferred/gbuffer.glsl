#pragma language glsl3

#define GPosition love_Canvases[0]
#define GNormal love_Canvases[1]
#define GAlbedoSpecular love_Canvases[2]
#define GVelocity love_Canvases[3]

varying vec3 v_fragPos;
varying vec4 v_clipPos;
varying vec4 v_prevClipPos;
varying vec2 v_texCoords;
varying mat3 v_tbnMatrix;

#ifdef VERTEX
attribute vec2 VertexTexCoords;
attribute vec3 VertexNormal;
attribute vec3 VertexTangent;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform mat4 u_prevTransform;
uniform bool u_isCanvasEnabled;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;

    // Calculating the TBN matrix for normal mapping
    vec3 T = normalize(vec3(u_world * vec4(VertexTangent,   0.0)));
    vec3 N = normalize(vec3(u_world * vec4(VertexNormal,    0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);

    // Assigning outputs
    v_tbnMatrix = mat3(T, B, N);
    v_fragPos = worldPos.xyz;
    v_texCoords = VertexTexCoords;
    v_clipPos = screen;
    v_prevClipPos = u_prevTransform * position;

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    if (u_isCanvasEnabled)
        screen.y *= -1.0;

    return screen;
}
#endif

#ifdef PIXEL
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform float u_shininess;

vec2 EncodeVelocity(vec2 vel);
#pragma include "engine/shaders/incl_utils.glsl"

void effect() {
    vec2 clipPos = (v_clipPos.xy / v_clipPos.w);
    vec2 prevClipPos = (v_prevClipPos.xy / v_prevClipPos.w);

    GPosition = vec4(v_fragPos, 1.0);
    GNormal = vec4(normalize(v_tbnMatrix * (Texel(u_normalMap, v_texCoords).rgb * 2.0 - 1.0)), 1.0);
    GAlbedoSpecular = vec4(Texel(u_diffuseTexture, v_texCoords).rgb, u_shininess);
    GVelocity = vec4(EncodeVelocity(clipPos - prevClipPos), 1, 1);
}
#endif