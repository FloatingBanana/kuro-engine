#define MATERIAL_DATA_CHANNELS 3
#define MATERIAL_DEPTH_PASS materialPrepass
#define MATERIAL_GBUFFER_PASS materialGBufferPass
#define MATERIAL_LIGHT_PASS materialLightingPass

#pragma include "engine/shaders/3D/material.glsl"
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_PBRLighting.glsl"

uniform struct MaterialInput {
	sampler2D normalMap;
	sampler2D albedoMap;
	sampler2D emissiveMap;
	sampler2D metallicRoughnessMap;
	sampler2D ambientOcclusionMap;
	float emissiveIntensity;
	float transparency;
} uInput;


uniform sampler2D u_ssaoTex;
uniform samplerCube u_irradianceMap;
uniform samplerCube u_environmentRadianceMap;


void materialPrepass() {
	if (Dither8(gl_FragCoord.xy, uInput.transparency))
		discard;
}


void materialGBufferPass(FragmentData fragData, out vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 normal = normalize(fragData.tbnMatrix * (texture(uInput.normalMap, fragData.uv).xyz * 2.0 - 1.0));
	vec3 albedo = texture(uInput.albedoMap, fragData.uv).rgb;
    vec4 metallicRoughness = texture(uInput.metallicRoughnessMap, fragData.uv);

	data[0] = vec4(EncodeNormal(normal), metallicRoughness.b, metallicRoughness.g);
	data[1] = vec4(albedo, 1.0);
	data[2] = vec4(texture(uInput.emissiveMap, fragData.uv).rgb * uInput.emissiveIntensity, 1.0);
}


vec4 materialLightingPass(FragmentData fragData, LightData light, vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 lightFragDirection = normalize(light.position - fragData.position);
    vec3 viewFragDirection = normalize(uViewPosition - fragData.position);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragData.position, 1.0);

	vec3 normal     = DecodeNormal(data[0].rg);
	float metallic  = data[0].b;
	float roughness = data[0].a;
	vec3 albedo     = data[1].rgb;
	float ao        = data[1].a;
	vec3 emissive   = data[2].rgb;
	vec3 result     = vec3(0.0);


#	if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        result = CalculateAmbientPBRLighting(light, u_irradianceMap, u_environmentRadianceMap, uBRDF_LUT, viewFragDirection, normal, albedo, roughness, metallic, ao);

#	else
		vec3 lightDir = CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL ? light.direction : lightFragDirection;
		result = CalculateDirectPBRLighting(light, lightDir, viewFragDirection, normal, albedo, roughness, metallic);
		result *= CalculateLightInfluence(light, fragData.position);
#	endif

	return vec4(result, 1.0);
}