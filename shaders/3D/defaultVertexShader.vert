#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"


in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

out vec3 v_fragPos;
out vec3 v_normal;
out vec4 v_screenPos;
out vec2 v_texCoords;
out mat3 v_tbnMatrix;

uniform mat4 u_volumeTransform;

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(uBoneMatrices, VertexBoneIDs, VertexWeights);
    vec4 worldPos = uWorldMatrix * skinMat * position;
    vec4 screen = uViewProjMatrix * worldPos;

#   if CURRENT_RENDER_PASS == RENDER_PASS_DEPTH_PREPASS
        screen.y *= -1.0;
        screen.z += 0.00001;
    
#   elif CURRENT_RENDER_PASS == RENDER_PASS_SHADOWMAPPING
        v_fragPos = worldPos.xyz;
        v_normal  = uInverseTransposedWorldMatrix * mat3(skinMat) * VertexNormal;

#   elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED_LIGHTPASS
        screen = u_volumeTransform * position * vec4(1,-1,1,1);

#   elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED
        v_tbnMatrix = GetTBNMatrix(uWorldMatrix, mat3(skinMat) * VertexNormal, mat3(skinMat) * VertexTangent);
        v_texCoords = VertexTexCoords;
        // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
        screen.y *= (uIsCanvasActive ? -1.0 : 1.0);

#   elif CURRENT_RENDER_PASS == RENDER_PASS_FORWARD
        v_tbnMatrix = GetTBNMatrix(uWorldMatrix, mat3(skinMat) * VertexNormal, mat3(skinMat) * VertexTangent);
        v_texCoords = VertexTexCoords;
        v_fragPos = worldPos.xyz;
        v_screenPos = screen;
        // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
        screen.y *= (uIsCanvasActive ? -1.0 : 1.0);
#   else
#       error Invalid render pass
#   endif

    return screen;
}