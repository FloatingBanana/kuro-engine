#pragma language glsl3
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

#ifndef CURRENT_LIGHT_TYPE
#   define CURRENT_LIGHT_TYPE LIGHT_TYPE_UNLIT
#endif

in vec2 v_texCoords;
in vec3 v_fragPos;
in vec4 v_screenPos;
in mat3 v_tbnMatrix;
in vec4 v_lightSpaceFragPos;

uniform LightData light;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform sampler2D u_ssaoTex;
uniform sampler2DShadow u_lightShadowMap;
uniform samplerCubeShadow u_pointLightShadowMap;


vec4 effect(EFFECTARGS) {
    vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));
    vec3 viewDir = normalize(uViewPosition - v_fragPos);
    vec3 diffuseColor = texture(u_diffuseTexture, v_texCoords).rgb;
    vec3 result = vec3(0.0);

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
        result = CaculatePhongLighting(light, light.direction, normal, viewDir, diffuseColor, u_shininess);
        result *= 1.0 - ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        result = CaculatePhongLighting(light, normalize(light.position - v_fragPos), normal, viewDir, diffuseColor, u_shininess);
        result *= CalculateSpotLight(light, v_fragPos);
        result *= 1.0 - ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
        result = CaculatePhongLighting(light, normalize(light.position - v_fragPos), normal, viewDir, diffuseColor, u_shininess);
        result *= CalculateSpotLight(light, v_fragPos);
        result *= 1.0 - ShadowCalculation(light.position, light.farPlane, u_pointLightShadowMap, uViewPosition, v_fragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        vec2 samplePos = (v_screenPos.xy / v_screenPos.w) * 0.5 + 0.5;

        result = light.color * diffuseColor;
        result *= texture(u_ssaoTex, samplePos).r;
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
        result = diffuseColor;
#   endif

    return vec4(result, 1.0);
}