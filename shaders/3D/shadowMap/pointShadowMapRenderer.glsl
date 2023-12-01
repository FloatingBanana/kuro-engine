#pragma language glsl3
#define MAX_BONE_COUNT 50


#ifdef VERTEX
in vec4 VertexBoneIDs;
in vec4 VertexWeights;
out vec4 v_fragPos;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];


mat4 GetSkinningMatrix(mat4 boneMatrices[MAX_BONE_COUNT], vec4 boneIDs, vec4 weights);
#pragma include "engine/shaders/incl_utils.glsl"

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);

    v_fragPos = u_world * skinMat * position;
    return u_viewProj * v_fragPos;
}
#endif


#ifdef PIXEL
uniform vec3 lightPos;
uniform float farPlane;
in vec4 v_fragPos;

void effect() {
    gl_FragDepth = length(v_fragPos.xyz - lightPos) / farPlane;
}
#endif