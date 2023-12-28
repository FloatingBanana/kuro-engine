#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"

#define oNormal love_Canvases[0]
#define oAlbedoSpecular love_Canvases[1]
#define oVelocity love_Canvases[2]


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

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(uBoneMatrices, VertexBoneIDs, VertexWeights);
    mat3 normalSkinMat = mat3(skinMat);
    
    position = skinMat * position;
    vec4 worldPos = uWorldMatrix * position;
    vec4 screen = uViewProjMatrix * worldPos;


    // Assigning outputs
    v_tbnMatrix   = GetTBNMatrix(uWorldMatrix, normalSkinMat * VertexNormal, normalSkinMat * VertexTangent);
    v_texCoords   = VertexTexCoords;
    v_clipPos     = screen;
    v_prevClipPos = uPrevTransform * position;

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (uIsCanvasActive ? -1 : 1);

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

    oNormal         = vec4(EncodeNormal(normal), 1.0, 1.0);
    oAlbedoSpecular = vec4(texture(u_diffuseTexture, v_texCoords).rgb, u_shininess);
    oVelocity       = vec4(EncodeVelocity(clipPos - prevClipPos), 1, 1);
}
#endif