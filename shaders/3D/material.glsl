#pragma language glsl3

#ifndef MATERIAL_DATA_CHANNELS
#   define MATERIAL_DATA_CHANNELS 8
#endif


#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

#define ISLIGHT(t) (CURRENT_LIGHT_TYPE == t)


in vec2 v_texCoords;
in vec3 v_fragPos;
in mat3 v_tbnMatrix;


struct FragmentData {
    vec3 position;
    vec2 uv;
    vec2 screenUV;
    mat3 tbnMatrix;
};


void materialGBufferPass(FragmentData fragData, out vec4 data[MATERIAL_DATA_CHANNELS]);
vec4 materialLightingPass(FragmentData fragData, LightData light, vec4 data[MATERIAL_DATA_CHANNELS]);
// vec4 materialAmbientPass(FragmentData fragData, LightData light, vec4 data[MATERIAL_DATA_CHANNELS]);
void materialPrepass();



float _getShadowOcclusion(LightData light, vec3 fragPos, vec3 viewPos) {
    vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragPos, 1.0);

#	if defined(MATERIAL_DISABLE_SHADOWS) || CURRENT_LIGHT_TYPE == LIGHT_TYPE_AMBIENT || CURRENT_LIGHT_TYPE == LIGHT_TYPE_UNLIT
		return 0.0;
#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL || CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        return ShadowCalculation(light.shadowMap, lightSpaceFragPos);
#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
		return ShadowCalculation(light.position, light.farPlane, light.pointShadowMap, viewPos, fragPos);
#   endif
}



#if CURRENT_RENDER_PASS == RENDER_PASS_DEPTH_PREPASS
void effect() {
    materialPrepass();
}


#elif CURRENT_RENDER_PASS == RENDER_PASS_FORWARD
uniform LightData u_light;
uniform sampler2D u_ambientOcclusion;

out vec4 oFragColor;

void effect() {
	FragmentData fragData;
	fragData.screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
    fragData.position = v_fragPos;
    fragData.tbnMatrix = v_tbnMatrix;
	
    vec4 inData[MATERIAL_DATA_CHANNELS];
    materialGBufferPass(fragData, inData);

    float visibility = 1.0;
    if (ISLIGHT(LIGHT_TYPE_AMBIENT)) {
        visibility = texture(u_ambientOcclusion, fragData.screenUV).r;
    }
    else {
        visibility = 1.0 - _getShadowOcclusion(u_light, v_fragPos, uViewPosition);
    }
}







#elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED
out vec4 oDeferredOutputs[MATERIAL_DATA_CHANNELS];

void effect() {
    FragmentData fragData;
    fragData.position = v_fragPos;
    fragData.tbnMatrix = v_tbnMatrix;


	materialPrepass();
    materialGBufferPass(fragData, oDeferredOutputs);
}


#elif CURRENT_RENDER_PASS == RENDER_PASS_DEFERRED_LIGHTPASS
uniform sampler2D u_deferredInput[MATERIAL_DATA_CHANNELS];
uniform sampler2D u_ambientOcclusion;

uniform LightData u_light;

out vec4 oFragColor;

void effect() {
    FragmentData fragData;
	fragData.screenUV = love_PixelCoord.xy / love_ScreenSize.xy;
    fragData.position = ReconstructPosition(fragData.screenUV, uDepthBuffer, uInvViewProjMatrix);

    vec4 inData[MATERIAL_DATA_CHANNELS];

#   if MATERIAL_DATA_CHANNELS >= 1
        inData[0] = texture(u_deferredInput[0], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 2
        inData[1] = texture(u_deferredInput[1], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 3
        inData[2] = texture(u_deferredInput[2], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 4
        inData[3] = texture(u_deferredInput[3], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 5
        inData[4] = texture(u_deferredInput[4], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 6
        inData[5] = texture(u_deferredInput[5], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 7
        inData[6] = texture(u_deferredInput[6], fragData.screenUV);
#   endif
#   if MATERIAL_DATA_CHANNELS >= 8
        inData[7] = texture(u_deferredInput[7], fragData.screenUV);
#   endif


    float visibility = 1.0;
    if (ISLIGHT(LIGHT_TYPE_AMBIENT)) {
        visibility = texture(u_ambientOcclusion, fragData.screenUV).r;
    }
    else {
        visibility = 1.0 - _getShadowOcclusion(u_light, fragData.position, uViewPosition);
    }
}
#endif