float ShadowCalculation(vec3 position, float farPlane, samplerCube shadowMap, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(sampler2D shadowMap, vec4 lightFragPos);
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

#ifndef PHONG_LIGHT_STRUCT_DECLARED
#define PHONG_LIGHT_STRUCT_DECLARED

struct PhongLight {
    vec3 position;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    // spot light
    float cutOff;
    float outerCutOff;

    // point light
    float constant;
    float linear;
    float quadratic;
    float farPlane;

    vec4 fragPos;
};
#endif

vec3 CaculatePhongLighting(PhongLight light, vec3 fragLightDir, vec3 normal, vec3 viewDir, float visibility, vec3 matDiffuseColor, float matShininess) {
    vec3 ambient = light.ambient * matDiffuseColor;
    vec3 diffuse = max(dot(normal, fragLightDir), 0.0) * light.diffuse * matDiffuseColor;

    vec3 halfwayDir = normalize(fragLightDir + viewDir);
    vec3 specular = pow(max(dot(normal, halfwayDir), 0.0), matShininess) * light.specular * vec3(1.0);

    return ambient + (diffuse + specular) * visibility;
}

vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess) {
    float shadow = ShadowCalculation(shadowMap, light.fragPos);
    return CaculatePhongLighting(light, light.direction, normal, viewDir, 1.0 - shadow, matDiffuseColor, matShininess);
}

vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess, vec3 fragPos) {
    vec3 fragLightDir = normalize(light.position - fragPos);
    float theta = dot(fragLightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
        float shadow = ShadowCalculation(shadowMap, light.fragPos);

        return CaculatePhongLighting(light, fragLightDir, normal, viewDir, (1.0 - shadow) * intensity, matDiffuseColor, matShininess);
    }
    
    return light.ambient * matDiffuseColor;
}

vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 viewPos, samplerCube shadowMap, vec3 matDiffuseColor, float matShininess, vec3 fragPos) {
    vec3 fragLightDir = normalize(light.position - fragPos);
    float dist = length(light.position - fragPos);

    float attenuation = 1.0 / (light.constant  + light.linear * dist + light.quadratic * (dist * dist));
    float shadow = ShadowCalculation(light.position, light.farPlane, shadowMap, viewPos, fragPos);

    return CaculatePhongLighting(light, fragLightDir, normal, viewDir, 1.0 - shadow, matDiffuseColor, matShininess) * attenuation;
}