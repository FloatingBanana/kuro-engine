#define MATERIAL_DATA_CHANNELS 2

#pragma include "engine/shaders/3D/material.glsl"
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_PhongLighting.glsl"

uniform struct MaterialInput {
	sampler2D normalMap;
	sampler2D diffuseMap;
	float shininess;
	float transparency;
} uInput;

uniform sampler2D u_ssaoTex;

void materialPrepass() {
	if (Dither8(gl_FragCoord.xy, uInput.transparency))
		discard;
}


void materialGBufferPass(FragmentData fragData, out vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 normal = normalize(v_tbnMatrix * (texture(uInput.normalMap, v_texCoords).xyz * 2.0 - 1.0));
	vec3 diffuse = texture(uInput.diffuseMap, v_texCoords).rgb;

	data[0] = vec4(EncodeNormal(normal), 1.0, 1.0);
	data[1] = vec4(diffuse, uInput.shininess / 255.0);
}


vec4 materialLightingPass(FragmentData fragData, LightData light, vec4 data[MATERIAL_DATA_CHANNELS]) {
	vec3 lightFragDirection = normalize(light.position - fragData.position);
    vec3 viewFragDirection = normalize(uViewPosition - fragData.position);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragData.position, 1.0);

	vec3 normal     = DecodeNormal(data[0].rg);
	vec3 diffuse    = data[1].rgb;
	float shininess = data[1].a * 255.0;
	vec3 result     = vec3(0.0);


#	if CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
        result = diffuse * light.color * texture(u_ssaoTex, fragData.screenUV).r;

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
        result = diffuse;
#	else
		vec3 lightDir = CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL ? light.direction : lightFragDirection;
		result = CaculatePhongLighting(light, lightDir, normal, viewFragDirection, diffuse, shininess);

#		if CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
			result *= CalculateSpotLight(light, fragData.position) * CalculatePointLight(light, fragData.position);
#		elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
			result *= CalculatePointLight(light, fragData.position);
#		endif
#   endif


	// result = result / (result + vec3(1.0));
    // result = pow(result, vec3(1.0/2.2));

	return vec4(result, 1.0);
}