#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

#define GNormal love_Canvases[0]
#define GAlbedoSpecular love_Canvases[1]
#define GVelocity love_Canvases[2]


varying vec4 v_clipPos;
varying vec4 v_prevClipPos;
varying vec2 v_texCoords;
varying mat3 v_tbnMatrix;


#ifdef VERTEX
in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform mat4 u_prevTransform;
uniform bool u_isCanvasEnabled;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];


vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);
    mat3 normalSkinMat = mat3(skinMat);
    
    position = skinMat * position;
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;


    // Assigning outputs
    v_tbnMatrix   = GetTBNMatrix(u_world, normalSkinMat * VertexNormal, normalSkinMat * VertexTangent);
    v_texCoords   = VertexTexCoords;
    v_clipPos     = screen;
    v_prevClipPos = u_prevTransform * position;

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (u_isCanvasEnabled ? -1 : 1);

    return screen;
}
#endif


#ifdef PIXEL
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform float u_shininess;

void effect() {
    vec2 clipPos = (v_clipPos.xy / v_clipPos.w);
    vec2 prevClipPos = (v_prevClipPos.xy / v_prevClipPos.w);
    vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));

    GNormal         = vec4(EncodeNormal(normal), 1.0, 1.0);
    GAlbedoSpecular = vec4(texture(u_diffuseTexture, v_texCoords).rgb, u_shininess);
    GVelocity       = vec4(EncodeVelocity(clipPos - prevClipPos), 1, 1);
}
#endif