#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

varying vec4 v_clipPos;
varying vec4 v_prevClipPos;


#ifdef VERTEX
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

uniform mat4 uViewProjMatrix;
uniform mat4 uWorldMatrix;
uniform mat4 uPrevTransform;
uniform mat4 uBoneMatrices[MAX_BONE_COUNT];

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(uBoneMatrices, VertexBoneIDs, VertexWeights);
    position = skinMat * position;

    vec4 screenPos = uViewProjMatrix * uWorldMatrix * position;
    v_clipPos = screenPos;
    v_prevClipPos = uPrevTransform * position;
    
    screenPos.y *= -1.0; // 3 days of my life wasted because of this bullshit
    screenPos.z += 0.00001; // Pre-pass bias to avoid depth conflict on some hardwares
    
    return screenPos;
}
#endif

#ifdef PIXEL
out vec4 oVelocity;

void effect() {
    vec2 pos = v_clipPos.xy / v_clipPos.w;
    vec2 prevPos = v_prevClipPos.xy / v_prevClipPos.w;

    oVelocity = vec4(EncodeVelocity(pos - prevPos), 1, 1);
}
#endif