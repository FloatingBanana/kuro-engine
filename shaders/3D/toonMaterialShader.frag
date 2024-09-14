#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_dither.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_toonLighting.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

#define ENABLE_SHADOWS


vec3 shadeFragmentPhong(LightData light, sampler2D ssaoTex, vec3 fragPos, vec3 normal, vec3 diffuseColor, float shininess) {
	vec3 viewFragDirection = normalize(uViewPosition - fragPos);
	vec3 lightFragDirection = normalize(light.position - fragPos);
	vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragPos, 1.0);
	vec2 screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
	vec3 result;

#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
		result = CaculateToonLighting(light, light.direction, normal, viewFragDirection, diffuseColor, shininess);
		result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
		result = CaculateToonLighting(light, lightFragDirection, normal, viewFragDirection, diffuseColor, shininess);
        result *= CalculateSpotLight(light, fragPos) * CalculatePointLight(light, fragPos);
		result *= 1.0 - ShadowCalculation(light.shadowMap, lightSpaceFragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
		result = CaculateToonLighting(light, lightFragDirection, normal, viewFragDirection, diffuseColor, shininess);
		result *= CalculatePointLight(light, fragPos);
		result *= 1.0 - ShadowCalculation(light.position, light.farPlane, light.pointShadowMap, uViewPosition, fragPos);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT
		result = light.color * diffuseColor;
		result *= texture(ssaoTex, screenUV).r;

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
		result = diffuseColor;
#   else
#       error Invalid light type
#   endif

	return result;
}


in vec2 v_texCoords;
in vec3 v_fragPos;
in mat3 v_tbnMatrix;


#if CURRENT_RENDER_PASS == RENDER_PASS_DEPTH_PREPASS
uniform float u_transparence;

void effect() {
	if (Dither8(gl_FragCoord.xy, u_transparence))
		discard;
}
#endif


#if CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform float u_transparence;

out vec4 oNormal;
out vec4 oAlbedoTreshold;

void effect() {
	if (Dither8(gl_FragCoord.xy, u_transparence))
		discard;

	vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));

	oNormal         = vec4(EncodeNormal(normal), 1.0, 1.0);
	oAlbedoTreshold = vec4(texture(u_diffuseTexture, v_texCoords).rgb, u_shininess / 255.0);
}
#endif



#if CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED_LIGHTPASS
uniform LightData light;
uniform sampler2D u_ssaoTex;
uniform sampler2D u_GNormal;
uniform sampler2D u_GAlbedoShininess;

out vec4 oFragColor;

void effect() {
	vec2 screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
	vec4 albedoShininess = texture(u_GAlbedoShininess, screenUV);

	vec3 result = shadeFragmentPhong(
		light,
		u_ssaoTex,
		ReconstructPosition(screenUV, uDepthBuffer, uInvViewProjMatrix),
		DecodeNormal(texture(u_GNormal, screenUV).xy),
		albedoShininess.rgb,
		albedoShininess.a * 255.0
	);

	oFragColor = vec4(result, 1.0);
}
#endif



#if CURRENT_RENDER_PASS == RENDER_PASS_FORWARD
uniform LightData light;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform sampler2D u_ssaoTex;

out vec4 oFragColor;

void effect() {
	vec3 result = shadeFragmentPhong(
		light,
		u_ssaoTex,
		v_fragPos,
		normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0)),
		texture(u_diffuseTexture, v_texCoords).rgb,
		u_shininess
	);

	oFragColor = vec4(result, 1.0);
}
#endif