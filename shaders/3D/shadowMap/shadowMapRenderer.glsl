#pragma language glsl3

#ifdef VERTEX
#pragma include "engine/shaders/incl_utils.glsl"

in vec3 VertexNormal;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

out vec3 v_fragPos;
out vec3 v_normal;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat3 u_invTranspWorld;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);
    vec4 fragPos = u_world * skinMat * position;

    v_fragPos = fragPos.xyz;
    v_normal  = u_invTranspWorld * mat3(skinMat) * VertexNormal;

    return u_viewProj * fragPos;
}
#endif

#ifdef PIXEL
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"

uniform LightData light;
in vec3 v_normal;
in vec3 v_fragPos;

#define BIAS(dir) (max(1.0 - dot(dir, v_normal), 0.1) * 0.000005)

void effect() {
#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
        gl_FragDepth = gl_FragCoord.z + BIAS(light.direction);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        gl_FragDepth = gl_FragCoord.z + BIAS(normalize(light.position - v_fragPos));

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
        gl_FragDepth = length(v_fragPos - light.position) / light.farPlane;
#   endif
}
#endif