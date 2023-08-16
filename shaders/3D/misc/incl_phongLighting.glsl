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


vec3 CaculatePhongLighting(PhongLight light, vec3 fragLightDir, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess) {
    vec3 diffuse = max(dot(normal, fragLightDir), 0.0) * light.diffuse * matDiffuseColor;

    vec3 halfwayDir = normalize(fragLightDir + viewDir);
    vec3 specular = pow(max(dot(normal, halfwayDir), 0.0), matShininess) * light.specular;

    return diffuse + specular;
}


vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess) {
    return CaculatePhongLighting(light, light.direction, normal, viewDir, matDiffuseColor, matShininess);
}


vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos) {
    vec3 fragLightDir = normalize(light.position - fragPos);
    float theta = dot(fragLightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

        return CaculatePhongLighting(light, fragLightDir, normal, viewDir, matDiffuseColor, matShininess) * intensity;
    }
    
    return vec3(0);
}


vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos) {
    vec3 fragLightDir = normalize(light.position - fragPos);
    float dist = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant  + light.linear * dist + light.quadratic * (dist * dist));

    return CaculatePhongLighting(light, fragLightDir, normal, viewDir, matDiffuseColor, matShininess) * attenuation;
}


vec3 CalculateAmbientLight(PhongLight light, vec3 matDiffuseColor) {
    return light.ambient * matDiffuseColor;
}