#define MATERIAL_DATA_CHANNELS 2
#define MATERIAL_INPUT_STRUCT MaterialInput

#define MATERIAL_DEPTH_PASS materialPrepass
#define MATERIAL_GBUFFER_PASS materialGBufferPass
#define MATERIAL_LIGHT_PASS materialLightingPass

struct MaterialInput {
	sampler2D normalMap;
	sampler2D diffuseMap;
	float shininess;
	float transparency;
};

#pragma include "engine/shaders/3D/material.glsl"
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_PhongLighting.glsl"


void materialPrepass(MaterialInput matInput) {
	if (Dither8(gl_FragCoord.xy, matInput.transparency))
		discard;
}


void materialGBufferPass(FragmentData fragData, MaterialInput matInput, out vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 normal = normalize(fragData.tbnMatrix * (texture(matInput.normalMap, fragData.uv).xyz * 2.0 - 1.0));
	vec3 diffuse = texture(matInput.diffuseMap, fragData.uv).rgb;

	data[0] = vec4(EncodeNormal(normal), 1.0, 1.0);
	data[1] = vec4(diffuse, matInput.shininess / 255.0);
}


vec4 materialLightingPass(FragmentData fragData, LightData light, MaterialInput matInput, vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 lightFragDirection = normalize(light.position - fragData.position);
    vec3 viewFragDirection = normalize(uViewPosition - fragData.position);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragData.position, 1.0);

	vec3 normal     = DecodeNormal(data[0].rg);
	vec3 diffuse    = data[1].rgb;
	float shininess = data[1].a * 255.0;
	vec3 result     = vec3(0.0);


#	if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        result = diffuse * light.color;
#	else
		vec3 lightDir = CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL ? light.direction : lightFragDirection;
		result = CaculatePhongLighting(light, lightDir, normal, viewFragDirection, diffuse, shininess);
		result *= CalculateLightInfluence(light, fragData.position);
#   endif

	return vec4(result, 1.0);
}