#pragma language glsl3

#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"

const float depthMultiplier = 1.0;
const float depthBias = 1.0;
const float normalMultiplier = 1.0;
const float normalBias = 10.0;


uniform float u_thickness = 5.0;
uniform vec4 u_outlineColor = vec4(0.0, 0.0, 0.0, 0.5);


float sampleDepth(sampler2D depthTex, vec2 uv, vec3 offset) {
    float center = LinearizeDepth(texture(depthTex, uv).r            , uNearPlane, uFarPlane);
    float left   = LinearizeDepth(texture(depthTex, uv - offset.xz).r, uNearPlane, uFarPlane);
    float right  = LinearizeDepth(texture(depthTex, uv + offset.xz).r, uNearPlane, uFarPlane);
    float up     = LinearizeDepth(texture(depthTex, uv + offset.zy).r, uNearPlane, uFarPlane);
    float down   = LinearizeDepth(texture(depthTex, uv - offset.zy).r, uNearPlane, uFarPlane);

    return
        abs(left  - center) + 
        abs(right - center) +
        abs(up    - center) +
        abs(down  - center);
}

vec3 sampleMeshNormal(sampler2D depthTex, vec2 uv, vec3 offset) {
    vec3 center = ReconstructNormal(depthTex, uv            , uInvProjMatrix);
    vec3 left   = ReconstructNormal(depthTex, uv - offset.xz, uInvProjMatrix);
    vec3 right  = ReconstructNormal(depthTex, uv + offset.xz, uInvProjMatrix);
    vec3 up     = ReconstructNormal(depthTex, uv + offset.zy, uInvProjMatrix);
    vec3 down   = ReconstructNormal(depthTex, uv - offset.zy, uInvProjMatrix);

    return
        abs(left  - center) + 
        abs(right - center) +
        abs(up    - center) +
        abs(down  - center);
}

vec3 sampleNormal(sampler2D normalTex, vec2 uv, vec3 offset) {
    vec3 center = DecodeNormal(texture(normalTex, uv            ).rg);
    vec3 left   = DecodeNormal(texture(normalTex, uv - offset.xz).rg);
    vec3 right  = DecodeNormal(texture(normalTex, uv + offset.xz).rg);
    vec3 up     = DecodeNormal(texture(normalTex, uv + offset.zy).rg);
    vec3 down   = DecodeNormal(texture(normalTex, uv - offset.zy).rg);

    return
        abs(left  - center) + 
        abs(right - center) +
        abs(up    - center) +
        abs(down  - center);
}

vec4 effect(vec4 _c, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 offset = vec3(1.0 / textureSize(uDepthBuffer, 0).xy, 0.0) * u_thickness * (1.0 - texture(uDepthBuffer, texcoords).r);

    float sobelDepth = sampleDepth(uDepthBuffer, texcoords, offset);
    sobelDepth = pow(clamp(sobelDepth, 0.0, 1.0) * depthMultiplier, depthBias);

    vec3 sobelNormalVec = sampleMeshNormal(uDepthBuffer, texcoords, offset);
    float sobelNormal = sobelNormalVec.x + sobelNormalVec.y + sobelNormalVec.z;
    sobelNormal = pow(clamp(sobelNormal, 0.0, 1.0) * normalMultiplier, normalBias);

    float outline = clamp(max(sobelDepth, sobelNormal), 0.0, 1.0);

    vec3 pixelColor = texture(tex, texcoords).rgb;
    vec3 lineColor = mix(pixelColor, u_outlineColor.rgb, u_outlineColor.a);
    vec3 finalColor = mix(pixelColor, lineColor, outline);

    return vec4(finalColor, 1.0);
}