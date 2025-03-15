#pragma language glsl3

#define MATERIAL_DATA_CHANNELS 4
#define MATERIAL_INPUT_STRUCT MaterialInput

#define MATERIAL_DEPTH_PASS materialPrepass
#define MATERIAL_GBUFFER_PASS materialGBufferPass
#define MATERIAL_LIGHT_PASS materialLightingPass

#pragma include "engine/shaders/include/incl_utils.glsl"
#pragma include "engine/shaders/include/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/include/incl_lights.glsl"
#pragma include "engine/shaders/include/incl_PBRLighting.glsl"
#pragma include "engine/shaders/include/incl_sphericalHarmonics.glsl"
#pragma include "engine/shaders/include/incl_irradianceVolume.glsl"



struct MaterialInput {
	sampler2D normalMap;
	sampler2D albedoMap;
	sampler2D emissiveMap;
	sampler2D metallicRoughnessMap;
	float emissiveIntensity;
	float transparency;

	IrradianceVolume irradianceVolume;

	SH9Color irradianceSH;
	samplerCube environmentRadianceMap;
};


#pragma include "engine/shaders/include/incl_material.glsl"


void materialPrepass(FragmentData fragData, MaterialInput matInput) {
	if (Dither8(fragData.screenPosition.xy, matInput.transparency))
		discard;
}


void materialGBufferPass(FragmentData fragData, MaterialInput matInput, out vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 normal = normalize(fragData.tbnMatrix * (texture(matInput.normalMap, fragData.uv).xyz * 2.0 - 1.0));
	vec3 albedo = texture(matInput.albedoMap, fragData.uv).rgb;
    vec4 metallicRoughness = texture(matInput.metallicRoughnessMap, fragData.uv);

	vec3 irradiance = IrrV_getIrradiance(matInput.irradianceVolume, fragData.position, normal);

	data[0] = vec4(EncodeNormal(normal), metallicRoughness.b, metallicRoughness.g);
	data[1] = vec4(albedo, 1.0);
	data[2] = vec4(texture(matInput.emissiveMap, fragData.uv).rgb * matInput.emissiveIntensity, 1.0);
	data[3] = vec4(irradiance, 1.0);
}


vec4 materialLightingPass(FragmentData fragData, LightData light, MaterialInput matInput, vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 lightFragDirection = normalize(light.position - fragData.position);
    vec3 viewFragDirection = normalize(uViewPosition - fragData.position);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragData.position, 1.0);

	vec3 normal     = DecodeNormal(data[0].rg);
	float metallic  = data[0].b;
	float roughness = data[0].a;
	vec3 albedo     = data[1].rgb;
	float ao        = data[1].a;
	vec3 emissive   = data[2].rgb;
	vec3 irradiance = data[3].rgb;
	vec3 result     = vec3(0.0);


#	if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
		result = CalculateAmbientPBRLighting(light, irradiance, matInput.environmentRadianceMap, uBRDF_LUT, viewFragDirection, normal, albedo, roughness, metallic, ao);
#	else
		vec3 lightDir = light.type == LIGHT_TYPE_DIRECTIONAL ? light.direction : lightFragDirection;
		result = CalculateDirectPBRLighting(light, lightDir, viewFragDirection, normal, albedo, roughness, metallic);
		result *= CalculateLightInfluence(light, fragData.position);
#	endif

	return vec4(result, 1.0);
}