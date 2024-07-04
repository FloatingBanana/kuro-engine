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
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

uniform LightData light;
uniform sampler2D u_ssaoTex;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec2 uv = screencoords / textureSize(uDepthBuffer, 0); // Handle various volume shapes

    vec4 albedoSpecular = texture(uGAlbedoSpecular, uv);
	
    vec3 fragPos   = ReconstructPosition(uv, uDepthBuffer, uInvViewProjMatrix);
    vec3 normal    = DecodeNormal(texture(uGNormal, uv).xy);
    vec3 albedo    = albedoSpecular.rgb;
    float specular = albedoSpecular.a * 255.0;

    vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragPos, 1.0);
    vec3 viewFragDirection = normalize(uViewPosition - fragPos);
    vec3 lightFragDirection = normalize(light.position - fragPos);

    vec3 result = vec3(0.0);


#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
        result = CaculatePhongLighting(light, light.direction, normal, viewFragDirection, albedo, specular);
        result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        result = CaculatePhongLighting(light, lightFragDirection, normal, viewFragDirection, albedo, specular);
        result *= CalculateSpotLight(light, fragPos);
        result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
        result = CaculatePhongLighting(light, lightFragDirection, normal, viewFragDirection, albedo, specular);
        result *= CalculatePointLight(light, fragPos);
        result *= 1.0 - ShadowCalculation(light.position, light.farPlane, light.pointShadowMap, uViewPosition, fragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        result = light.color * albedo;
        result *= texture(u_ssaoTex, texcoords).r;

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
        result = albedo;
#   else
#       error Invalid light type
#   endif


    return vec4(result, 1.0);
}

#endif