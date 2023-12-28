#pragma language glsl3

#ifdef VERTEX
uniform mat4 u_volumeTransform;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 screenPos = u_volumeTransform * position;
    screenPos.y *= -1.0;

    return screenPos;
}
#endif

#ifdef PIXEL
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

uniform PhongLight light;
uniform sampler2D u_ssaoTex;
uniform sampler2D u_lightShadowMap;
uniform samplerCube u_pointLightShadowMap;
uniform mat4 u_lightMatrix;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec2 uv = screencoords / textureSize(uDepthBuffer, 0); // Handle various volume shapes

	vec4 albedoSpecular = texture(uGAlbedoSpecular, uv);
	
    vec3 fragPos   = ReconstructPosition(uv, uDepthBuffer, uInvViewProjMatrix);
    vec3 normal    = DecodeNormal(texture(uGNormal, uv).xy);
    vec3 albedo    = albedoSpecular.rgb;
    float specular = albedoSpecular.a * 32.0;

    vec4 lightSpaceFragPos = u_lightMatrix * vec4(fragPos, 1.0);
    vec3 viewDir = normalize(uViewPosition - fragPos);
    vec3 result = vec3(0);
    float shadow = 0;

#   ifdef LIGHT_TYPE_DIRECTIONAL
        result = CalculateDirectionalLight(light, normal, viewDir, albedo, specular);
        shadow = ShadowCalculation(u_lightShadowMap, lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_SPOT
        result = CalculateSpotLight(light, normal, viewDir, albedo, specular, fragPos);
        shadow = ShadowCalculation(u_lightShadowMap, lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_POINT
        result = CalculatePointLight(light, normal, viewDir, albedo, specular, fragPos);
        shadow = ShadowCalculation(light.position, light.farPlane, u_pointLightShadowMap, uViewPosition, fragPos);
#   endif

#   ifdef LIGHT_TYPE_AMBIENT
        result = CalculateAmbientLight(light, albedo);
        shadow = 1.0 - texture(u_ssaoTex, uv).r;
#   endif

    return vec4(result * (1.0 - shadow), 1.0);
}

#endif