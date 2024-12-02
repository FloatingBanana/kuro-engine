#pragma language glsl3
#pragma include "engine/shaders/include/incl_utils.glsl"
#pragma include "engine/shaders/include/incl_meshSkinning.glsl"
#pragma include "engine/shaders/include/incl_dualQuaternion.glsl"
#pragma include "engine/shaders/include/incl_commonBuffers.glsl"


in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

out vec3 v_fragPos;
out vec3 v_normal;
out vec2 v_texCoords;
out mat3 v_tbnMatrix;

uniform mat4 u_volumeTransform;

vec4 position(mat4 transformProjection, vec4 position) {
    DualQuaternion dqSkinning = uHasAnimation ? GetDualQuaternionSkinning(uBoneQuaternions, VertexBoneIDs, VertexWeights) : dq_identity();
    vec3 scaleSkinning = uHasAnimation ? GetScalingSkinning(uBoneScaling, VertexBoneIDs, VertexWeights) : vec3(1.0);

    vec4 worldPos = uWorldMatrix * vec4(scaleSkinning * dq_transform(dqSkinning, position.xyz), 1.0);
    vec4 screen = uViewProjMatrix * worldPos;
    vec3 normal = dq_rotate(dqSkinning, VertexNormal);
    vec3 tangent = dq_rotate(dqSkinning, VertexTangent);

#   if CURRENT_RENDER_PASS == RENDER_PASS_DEPTH_PREPASS
        screen.z += 0.00001;
        screen.y *= -1;

#   elif CURRENT_RENDER_PASS == RENDER_PASS_SHADOWMAPPING
        v_fragPos = worldPos.xyz;
        v_normal  = uInverseTransposedWorldMatrix * normal;

#   elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED_LIGHTPASS
        screen = u_volumeTransform * position;

#   elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED
        v_tbnMatrix = GetTBNMatrix(uWorldMatrix, normal, tangent);
        v_texCoords = VertexTexCoords;

#   elif CURRENT_RENDER_PASS == RENDER_PASS_FORWARD
        v_tbnMatrix = GetTBNMatrix(uWorldMatrix, normal, tangent);
        v_texCoords = VertexTexCoords;
        v_fragPos = worldPos.xyz;
#   else
#       error Invalid render pass
#   endif
    
    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (uIsCanvasActive ? -1.0 : 1.0);

    return screen;
}