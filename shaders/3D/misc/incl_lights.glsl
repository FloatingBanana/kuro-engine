#define LIGHT_TYPE_UNLIT 0
#define LIGHT_TYPE_AMBIENT 1
#define LIGHT_TYPE_DIRECTIONAL 2
#define LIGHT_TYPE_SPOT 3
#define LIGHT_TYPE_POINT 4

struct LightData {
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


float CalculateSpotLight(LightData light, vec3 fragPos) {
    vec3 fragLightDir = normalize(light.position - fragPos);
    float theta = dot(fragLightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

        return intensity;
    }
    
    return 0.0;
}


float CalculatePointLight(LightData light, vec3 fragPos) {
    float dist = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * dist + light.quadratic * (dist * dist) + 0.0001);

    return attenuation;
}