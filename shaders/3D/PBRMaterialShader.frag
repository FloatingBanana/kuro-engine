#pragma language glsl3

#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_PBRLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"



vec3 shadeFragmentPBR(LightData light, vec3 fragPos, vec3 normal, vec3 albedo, float metallic, float roughness, float ao, samplerCube irradianceMap, samplerCube environmentRadianceMap) {
	vec3 lightFragDirection = normalize(light.position - fragPos);
    vec3 viewFragDirection = normalize(uViewPosition - fragPos);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragPos, 1.0);
	vec3 result = vec3(0.0);

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
        result = CalculateDirectPBRLighting(light, light.direction, viewFragDirection, normal, albedo, roughness, metallic);
        result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        result = CalculateDirectPBRLighting(light, lightFragDirection, viewFragDirection, normal, albedo, roughness, metallic);
        result *= CalculateSpotLight(light, fragPos) * CalculatePointLight(light, fragPos);
        result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
        result = CalculateDirectPBRLighting(light, lightFragDirection, viewFragDirection, normal, albedo, roughness, metallic);
        result *= CalculatePointLight(light, fragPos);
        result *= 1.0 - ShadowCalculation(light.position, light.farPlane, light.pointShadowMap, uViewPosition, fragPos);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        result = CalculateAmbientPBRLighting(light, irradianceMap, environmentRadianceMap, uBRDF_LUT, viewFragDirection, normal, albedo, roughness, metallic, ao);
#   endif

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
        result = albedo;
#   endif


	// result = result / (result + vec3(1.0));
    // result = pow(result, vec3(1.0/2.2));

	return result;
}



in vec2 v_texCoords;
in vec3 v_fragPos;
in vec4 v_screenPos;
in mat3 v_tbnMatrix;


#if CURRENT_RENDER_PASS == RENDER_PASS_DEPTH_PREPASS
uniform float u_transparence;

void effect() {
	if (Dither8(gl_FragCoord.xy, u_transparence))
		discard;
}
#endif



#if CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED
uniform sampler2D u_normalMap;
uniform sampler2D u_albedoMap;
uniform sampler2D u_metallicRoughnessMap;
uniform sampler2D u_ao;
uniform float u_transparence;

out vec4 oNormalMetallicRoughness;
out vec4 oAlbedoAO;

void effect() {
	if (Dither8(gl_FragCoord.xy, u_transparence))
		discard;

	vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).xyz * 2.0 - 1.0));
	vec3 albedo = texture(u_albedoMap, v_texCoords).rgb;
    vec4 metallicRoughness = texture(u_metallicRoughnessMap, v_texCoords);
    float ao = 1.0;

	oNormalMetallicRoughness = vec4(EncodeNormal(normal), metallicRoughness.b, metallicRoughness.g);
	oAlbedoAO = vec4(albedo, ao);
}
#endif



#if CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED_LIGHTPASS
uniform LightData light;
uniform sampler2D u_GNormalMetallicRoughness;
uniform sampler2D u_GAlbedoAO;

uniform sampler2D u_ssaoTex;
uniform samplerCube u_irradianceMap;
uniform samplerCube u_environmentRadianceMap;

out vec4 oFragColor;

void effect() {
	vec2 screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
	vec4 normalMetallicRoughness = texture(u_GNormalMetallicRoughness, screenUV);
	vec4 albedoAO = texture(u_GAlbedoAO, screenUV);

	vec3 result = shadeFragmentPBR(
		light,
		ReconstructPosition(screenUV, uDepthBuffer, uInvViewProjMatrix),
		DecodeNormal(normalMetallicRoughness.xy),
		albedoAO.rgb,
		normalMetallicRoughness.b,
		normalMetallicRoughness.a,
		albedoAO.a * texture(u_ssaoTex, screenUV).r,
		u_irradianceMap,
		u_environmentRadianceMap
	);

	oFragColor = vec4(result, 1.0);
}
#endif



#if CURRENT_RENDER_PASS == RENDER_PASS_FORWARD
uniform LightData light;
uniform sampler2D u_normalMap;
uniform sampler2D u_albedoMap;
uniform sampler2D u_metallicRoughnessMap;
uniform sampler2D u_ao;

uniform sampler2D u_ssaoTex;
uniform samplerCube u_irradianceMap;
uniform samplerCube u_environmentRadianceMap;

out vec4 oFragColor;

void effect() {
	vec2 screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
	vec4 metallicRoughness = texture(u_metallicRoughnessMap, v_texCoords);

	vec3 result = shadeFragmentPBR(
		light,
		v_fragPos,
		normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).xyz * 2.0 - 1.0)),
		texture(u_albedoMap, v_texCoords).rgb,
		metallicRoughness.b,
		metallicRoughness.g,
		texture(u_ssaoTex, screenUV).r,
		u_irradianceMap,
		u_environmentRadianceMap
	);


	oFragColor = vec4(result, 1.0);
}
#endif