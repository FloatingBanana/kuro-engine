#pragma language glsl3
#define MAX_BONE_COUNT 50


#ifdef VERTEX
in vec3 VertexNormal;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;
out vec3 v_normal;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat3 u_invTranspWorld;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];


mat4 GetSkinningMatrix(mat4 boneMatrices[MAX_BONE_COUNT], vec4 boneIDs, vec4 weights);
#pragma include "engine/shaders/incl_utils.glsl"

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);

    v_normal = u_invTranspWorld * mat3(skinMat) * VertexNormal;
    return u_viewProj * u_world * skinMat * position;
}
#endif

#ifdef PIXEL
uniform vec3 lightDir;
in vec3 v_normal;

void effect() {
    float bias = max(0.05 * (1.0 - dot(lightDir, v_normal)), 0.005);
    gl_FragDepth = gl_FragCoord.z + (gl_FrontFacing ? bias : 0.0);
}
#endif