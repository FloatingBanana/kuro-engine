#pragma include "engine/shaders/include/incl_lights.glsl"

const float rimTreshold = 0.2;
const float rimAmount = 0.6;

vec3 CaculateToonLighting(LightData light, vec3 fragLightDir, vec3 normal, vec3 viewDir, vec3 diffuseColor, float shininess) {
    vec3 halfway = normalize(fragLightDir + viewDir);
    float NdotH = dot(normal, halfway);
    float NdotL = dot(normal, fragLightDir);
    float NdotV = dot(normal, viewDir);

    float diffuse = smoothstep(0.0, 0.1, NdotL);
    float specular = smoothstep(0.05, 0.1, pow(NdotH * diffuse, shininess*shininess));

    
    float rimIntensity = (1.0 - NdotV) * pow(NdotL, rimTreshold);
    float rim = smoothstep(rimAmount-0.01, rimAmount+0.01, rimIntensity);

    return diffuseColor * (light.color*diffuse + light.specular*specular + light.color*rim);
}