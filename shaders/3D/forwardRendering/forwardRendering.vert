#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"


in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

out vec3 v_fragPos;
out vec4 v_screenPos;
out vec2 v_texCoords;
out mat3 v_tbnMatrix; 
out vec4 v_lightSpaceFragPos;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform bool u_isCanvasEnabled;
uniform mat4 u_lightMatrix;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];


vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);
    vec4 worldPos = u_world * skinMat * position;
    vec4 screen = u_viewProj * worldPos;
    
    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    screen.y *= (u_isCanvasEnabled ? -1 : 1);

    // Assigning outputs
    v_tbnMatrix = GetTBNMatrix(u_world, mat3(skinMat) * VertexNormal, mat3(skinMat) * VertexTangent);
    v_fragPos = worldPos.xyz;
    v_screenPos = screen;
    v_texCoords = VertexTexCoords;
    v_lightSpaceFragPos = u_lightMatrix * vec4(worldPos.xyz, 1.0);

    return screen;
}