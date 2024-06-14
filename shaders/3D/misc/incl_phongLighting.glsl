#pragma include "engine/shaders/3D/misc/incl_lights.glsl"

vec3 CaculatePhongLighting(LightData light, vec3 fragLightDir, vec3 normal, vec3 viewDir, vec3 diffuseColor, float shininess) {
    vec3 diffuse = max(dot(normal, fragLightDir), 0.0) * light.color * diffuseColor;

    vec3 halfwayDir = normalize(fragLightDir + viewDir);
    vec3 specular = pow(max(dot(normal, halfwayDir), 0.0), shininess) * light.specular;

    return diffuse + specular;
}