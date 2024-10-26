#define LIGHT_TYPE_UNLIT 0
#define LIGHT_TYPE_AMBIENT 1
#define LIGHT_TYPE_DIRECTIONAL 2
#define LIGHT_TYPE_SPOT 3
#define LIGHT_TYPE_POINT 4

struct LightData {
    int type;

    vec3 position;
    vec3 direction;

    vec3 color;
    vec3 specular;

    // spot light
    float cutOff;
    float outerCutOff;

    // point light
    float constant;
    float linear;
    float quadratic;
    float farPlane;

    mat4 lightMatrix;

    sampler2DShadow shadowMap;
    samplerCubeShadow pointShadowMap;
};


float CalculateSpotCone(vec3 lightPos, vec3 lightDir, float cutOff, float outerCutOff, vec3 fragPos) {
    vec3 fragLightDir = normalize(lightPos - fragPos);
    float theta = dot(fragLightDir, -lightDir);

    if (theta > outerCutOff) {
        float epsilon = cutOff - outerCutOff;
        return clamp((theta - outerCutOff) / epsilon, 0.0, 1.0);
    }
    
    return 0.0;
}


float CalculateAttenuation(vec3 lightPos, float constant, float linear, float quadratic, vec3 fragPos) {
    float dist = length(lightPos - fragPos);
    return 1.0 / (constant + linear * dist + quadratic * (dist * dist) + 0.0001);
}


float CalculateLightInfluence(LightData light, vec3 fragPos) {
    switch (light.type) {
        case LIGHT_TYPE_POINT:
            return CalculateAttenuation(light.position, light.constant, light.linear, light.quadratic, fragPos);
        case LIGHT_TYPE_SPOT:
            return CalculateAttenuation(light.position, light.constant, light.linear, light.quadratic, fragPos) * CalculateSpotCone(light.position, light.direction, light.cutOff, light.outerCutOff, fragPos);
        default:
            return 1.0;
    }
}