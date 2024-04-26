#pragma language glsl3
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

in vec2 v_texCoords;
in vec3 v_fragPos;
in vec4 v_screenPos;
in mat3 v_tbnMatrix;
in vec4 v_lightSpaceFragPos;

uniform PhongLight light;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform sampler2D u_ssaoTex;
uniform sampler2DShadow u_lightShadowMap;
uniform samplerCubeShadow u_pointLightShadowMap;


vec4 effect(EFFECTARGS) {
    vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));
    vec3 viewDir = normalize(uViewPosition - v_fragPos);
    vec3 diffuseColor = texture(u_diffuseTexture, v_texCoords).xyz;
    vec3 result = vec3(0);
    float shadow = 0;

#   ifdef LIGHT_TYPE_DIRECTIONAL
        result = CalculateDirectionalLight(light, normal, viewDir, diffuseColor, u_shininess);
        shadow = ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_SPOT
        result = CalculateSpotLight(light, normal, viewDir, diffuseColor, u_shininess, v_fragPos);
        shadow = ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_POINT
        result = CalculatePointLight(light, normal, viewDir, diffuseColor, u_shininess, v_fragPos);
        shadow = ShadowCalculation(light.position, light.farPlane, u_pointLightShadowMap, uViewPosition, v_fragPos);
#   endif

#   ifdef LIGHT_TYPE_AMBIENT
        vec2 samplePos = (v_screenPos.xy / v_screenPos.w) * 0.5 + 0.5;

        result = CalculateAmbientLight(light, diffuseColor);
        shadow = 1.0 - texture(u_ssaoTex, samplePos).r;
#   endif

    return vec4(result * (1.0 - shadow), 1.0);
}