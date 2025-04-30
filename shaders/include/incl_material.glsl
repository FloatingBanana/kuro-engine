#pragma language glsl3

#pragma include "engine/shaders/include/incl_utils.glsl"
#pragma include "engine/shaders/include/incl_commonBuffers.glsl"
#pragma include "engine/shaders/include/incl_lights.glsl"
#pragma include "engine/shaders/include/incl_shadowCalculation.glsl"
#pragma include "engine/shaders/include/incl_meshSkinning.glsl"
#pragma include "engine/shaders/include/incl_dualQuaternion.glsl"

#define ISLIGHT(t) (CURRENT_LIGHT_TYPE == t)
#define ISRENDERPASS(p) (CURRENT_RENDER_PASS == p)


#ifndef MATERIAL_DATA_CHANNELS
#   define MATERIAL_DATA_CHANNELS 8
#endif

#ifndef MATERIAL_DEPTH_PASS
#   define MATERIAL_DEPTH_PASS defaultDepthPass
#endif

#ifndef MATERIAL_GBUFFER_PASS
#   define MATERIAL_GBUFFER_PASS defaultGBufferPass
#endif

#ifndef MATERIAL_LIGHT_PASS
#   define MATERIAL_LIGHT_PASS defaultLightPass
#endif

#ifndef MATERIAL_INPUT_STRUCT
#   define MATERIAL_INPUT_STRUCT DefaultMaterialInput
#endif

#ifndef CURRENT_LIGHT_TYPE
#   define CURRENT_LIGHT_TYPE LIGHT_TYPE_AMBIENT
#endif

// #define MATERIAL_DISABLE_SHADOWS

#ifdef VERTEX
#   define MAT_VARYING out
#   define discard // Ugh...
#else
#   define MAT_VARYING in
#endif


MAT_VARYING vec3 v_fragPos;
MAT_VARYING vec3 v_normal;
MAT_VARYING vec2 v_texCoords;
MAT_VARYING mat3 v_tbnMatrix;


struct FragmentData {
    vec3 position;
    vec3 normal;
    vec2 uv;
    vec2 screenPosition;
    vec2 screenUV;
    mat3 tbnMatrix;
};

struct DefaultMaterialInput {
    int dummy;
};

void MATERIAL_DEPTH_PASS(FragmentData fragData, MATERIAL_INPUT_STRUCT materialInput);
void MATERIAL_GBUFFER_PASS(FragmentData fragData, MATERIAL_INPUT_STRUCT materialInput, out vec4 data[MATERIAL_DATA_CHANNELS]);
vec4 MATERIAL_LIGHT_PASS(FragmentData fragData, LightData light, MATERIAL_INPUT_STRUCT materialInput, vec4 data[MATERIAL_DATA_CHANNELS]);


void defaultDepthPass(FragmentData fragData, MATERIAL_INPUT_STRUCT materialInput) {}
void defaultGBufferPass(FragmentData fragData, MATERIAL_INPUT_STRUCT materialInput, out vec4 data[MATERIAL_DATA_CHANNELS]) {}
vec4 defaultLightPass(FragmentData fragData, LightData light, MATERIAL_INPUT_STRUCT materialInput, vec4 data[MATERIAL_DATA_CHANNELS]) {return vec4(0,0,0,1);}




float _getShadowOcclusion(LightData light, FragmentData fragData, vec3 viewPos) {
    vec4 lightSpaceFragPos = light.lightMatrix * vec4(fragData.position, 1.0);

#	if defined(MATERIAL_DISABLE_SHADOWS)
		return 0.0;
#   elif ISLIGHT(LIGHT_TYPE_DIRECTIONAL) || ISLIGHT(LIGHT_TYPE_SPOT)
        return ShadowCalculation(light.shadowMap, lightSpaceFragPos, light.direction, fragData.normal);
#   elif ISLIGHT(LIGHT_TYPE_POINT)
		return ShadowCalculation(light.position, light.farPlane, light.pointShadowMap, viewPos, fragData.position);
#   else
        return 0.0;
#   endif
}

FragmentData _getFragmentData(vec2 fragCoord) {
    FragmentData fragData;
    fragData.position = v_fragPos;
    fragData.normal = v_normal;
    fragData.uv = v_texCoords;
    fragData.tbnMatrix = v_tbnMatrix;
    fragData.screenPosition = fragCoord;
    fragData.screenUV = fragCoord / love_ScreenSize.xy;

    return fragData;
}




#ifdef VERTEX
in vec2 VertexTexCoords;
in vec3 VertexNormal;
in vec3 VertexTangent;
in vec4 VertexBoneIDs;
in vec4 VertexWeights;


vec4 position(mat4 transformProjection, vec4 position) {
    DualQuaternion dqSkinning = uHasAnimation ? GetDualQuaternionSkinning(uBoneQuaternions, VertexBoneIDs, VertexWeights) : dq_identity();
    vec3 scaleSkinning = uHasAnimation ? GetScalingSkinning(uBoneScaling, VertexBoneIDs, VertexWeights) : vec3(1.0);

    vec4 worldPos = uWorldMatrix * vec4(scaleSkinning * dq_transform(dqSkinning, position.xyz), 1.0);
    vec4 screen = uViewProjMatrix * worldPos;
    vec3 normal = dq_rotate(dqSkinning, VertexNormal);
    vec3 tangent = dq_rotate(dqSkinning, VertexTangent);

    v_fragPos = worldPos.xyz;
    v_tbnMatrix = GetTBNMatrix(uWorldMatrix, normal, tangent);
    v_texCoords = VertexTexCoords;
    v_normal  = uInverseTransposedWorldMatrix * normal;

#   if ISRENDERPASS(RENDER_PASS_DEFERRED_LIGHTPASS)
        screen = uWorldMatrix * position;
#   elif ISRENDERPASS(RENDER_PASS_DEPTH_PREPASS)
        screen.z += 0.00001;
		screen.y *= -1.0;
#   endif


    screen.y *= uIsCanvasActive ? -1.0 : 1.0; // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back

    return screen;
}
#endif // VERTEX





#if defined(PIXEL) && ISRENDERPASS(RENDER_PASS_DEPTH_PREPASS)
uniform MATERIAL_INPUT_STRUCT u_input;

void effect() {
    MATERIAL_DEPTH_PASS(_getFragmentData(gl_FragCoord.xy), u_input);
}
#endif // RENDER_PASS_DEPTH_PREPASS




#if defined(PIXEL) && ISRENDERPASS(RENDER_PASS_FORWARD)
uniform LightData u_light;
uniform MATERIAL_INPUT_STRUCT u_input;
uniform sampler2D u_ambientOcclusion;

out vec4 oFragColor;

void effect() {
	FragmentData fragData = _getFragmentData(gl_FragCoord.xy);

    vec4 inData[MATERIAL_DATA_CHANNELS];
    MATERIAL_GBUFFER_PASS(fragData, u_input, inData);

    float visibility = 1.0;
#   if ISLIGHT(LIGHT_TYPE_AMBIENT)
        visibility = texture(u_ambientOcclusion, fragData.screenUV).r;
#   else
        visibility = 1.0 - _getShadowOcclusion(u_light, fragData, uViewPosition);
#   endif

	oFragColor = MATERIAL_LIGHT_PASS(fragData, u_light, u_input, inData) * visibility;
}
#endif // RENDER_PASS_FORWARD






#if defined(PIXEL) && ISRENDERPASS(RENDER_PASS_DEFERRED)
uniform MATERIAL_INPUT_STRUCT u_input;
out vec4 oDeferredOutputs[MATERIAL_DATA_CHANNELS];

void effect() {
    FragmentData fragData = _getFragmentData(gl_FragCoord.xy);

	MATERIAL_DEPTH_PASS(fragData, u_input);
    MATERIAL_GBUFFER_PASS(fragData, u_input, oDeferredOutputs);
}
#endif // RENDER_PASS_DEFERRED




#if defined(PIXEL) && ISRENDERPASS(RENDER_PASS_DEFERRED_LIGHTPASS)
uniform sampler2D u_deferredInput[MATERIAL_DATA_CHANNELS];
uniform sampler2D u_ambientOcclusion;
uniform MATERIAL_INPUT_STRUCT u_input;
uniform LightData u_light;

out vec4 oFragColor;

void effect() {
    FragmentData fragData = _getFragmentData(gl_FragCoord.xy);
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
#   if ISLIGHT(LIGHT_TYPE_AMBIENT)
        visibility = texture(u_ambientOcclusion, fragData.screenUV).r;
#   else
        visibility = 1.0 - _getShadowOcclusion(u_light, fragData, uViewPosition);
#   endif
    
    oFragColor = MATERIAL_LIGHT_PASS(fragData, u_light, u_input, inData) * visibility;
}
#endif // RENDER_PASS_DEFERRED_LIGHTPASS