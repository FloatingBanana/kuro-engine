#pragma language glsl3
#define SHADOW_BIAS 0.0005
#define POINT_SHADOW_BIAS 0.5
#define POINT_SAMPLES 20

const vec3 sampleOffsetDirections[POINT_SAMPLES] = vec3[] (
   vec3( 1, 1, 1), vec3( 1,-1, 1), vec3(-1,-1, 1), vec3(-1, 1, 1), 
   vec3( 1, 1,-1), vec3( 1,-1,-1), vec3(-1,-1,-1), vec3(-1, 1,-1),
   vec3( 1, 1, 0), vec3( 1,-1, 0), vec3(-1,-1, 0), vec3(-1, 1, 0),
   vec3( 1, 0, 1), vec3(-1, 0, 1), vec3( 1, 0,-1), vec3(-1, 0,-1),
   vec3( 0, 1, 1), vec3( 0,-1, 1), vec3( 0,-1,-1), vec3( 0, 1,-1)
);

// Point light
float ShadowCalculation(vec3 position, float farPlane, samplerCubeShadow shadowMap, vec3 viewPos, vec3 fragPos) {
    vec3 fragToLight = fragPos - position;
    float currentDepth = (length(fragToLight) - POINT_SHADOW_BIAS) / farPlane;

    float viewDist = length(viewPos - fragPos);
    float diskRadius = (1.0 + (viewDist / farPlane)) / 25.0;
    float shadow = 0.0;

    for (int i=0; i < POINT_SAMPLES; i++) {
        shadow += texture(shadowMap, vec4(fragToLight + sampleOffsetDirections[i] * diskRadius, currentDepth));
    }

    return shadow / float(POINT_SAMPLES);
}

// Directional and spot lights
float ShadowCalculation(sampler2DShadow shadowMap, vec4 lightFragPos, vec3 lightDir, vec3 normal) {
    vec3 projCoords = (lightFragPos.xyz / lightFragPos.w) * 0.5 + 0.5;

    if (projCoords.z > 1.0)
        return 0.0;
    
    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    float bias = max(1.0 - dot(normal, lightDir), 0.1) * SHADOW_BIAS;

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            shadow += texture(shadowMap, projCoords + vec3(vec2(x, y) * texelSize, -bias));
        }
    }

    return shadow / 9.0;
}