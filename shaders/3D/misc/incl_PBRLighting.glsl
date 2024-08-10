#pragma include "engine/shaders/3D/misc/incl_lights.glsl"

struct PBRFragment {
    vec3 albedo;
    float metallic;
    float roughness;
    float ambientOcclusion;
};


vec3 BaseFresnelReflection(vec3 albedo, float metallic) {
    return mix(vec3(0.04), albedo, metallic);
}

vec3 FresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float DistributionGGX(float NdotH, float roughness) {
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH2 = NdotH*NdotH;

    float denom = (NdotH2 * (a2 - 1.0) + 1.0) + 0.0001;
    denom = PI * denom*denom;

    return a2 / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r*r) * 0.125;// / 8.0;
    float denom = NdotV * (1.0 - k) + k + 0.0001;
    
    return NdotV / denom;
}

float GeometrySmith(float NdotV, float NdotL, float roughness) {
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}



vec3 CalculateDirectPBRLighting(LightData light, vec3 lightDirection, vec3 viewFragDirection, vec3 normal, vec3 albedo, float roughness, float metallic) {
    vec3 F0 = BaseFresnelReflection(albedo, metallic);
    
    vec3 N = normal;
    vec3 V = viewFragDirection;
    vec3 L = lightDirection;
    vec3 H = normalize(V + L);

    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);

    float NDF = DistributionGGX(NdotH, roughness);
    float G = GeometrySmith(NdotV, NdotL, roughness);
    vec3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

    vec3 kS = F;
    vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);

    vec3 num = NDF * G * F;
    float denom = 4.0 * NdotV * NdotL + 0.0001;
    vec3 specular = num / denom;

    return (kD * albedo / PI + specular) * light.color * NdotL;
}


vec3 CalculateAmbientPBRLighting(LightData light, samplerCube irradianceMap, samplerCube prefilteredEnvironmentMap, sampler2D brdfLUT, vec3 viewFragDirection, vec3 normal, vec3 albedo, float roughness, float metallic, float ao) {
    vec3 N = normal;
    vec3 V = viewFragDirection;
    vec3 F0 = BaseFresnelReflection(albedo, metallic);

    const float MAX_REFLECTION_LOD = 4.0;
    float NdotV = max(dot(N, V), 0.0);
    vec3 R = reflect(-V, N);
    
    vec3 F = FresnelSchlickRoughness(NdotV, F0, roughness);
    vec3 kS = F;
    vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);
    
    vec3 irradiance = texture(irradianceMap, N).rgb;
    vec3 diffuse = irradiance * albedo;

    vec3 prefilteredColor = textureLod(prefilteredEnvironmentMap, R, roughness * MAX_REFLECTION_LOD).rgb;
    vec2 envBRDF = texture(brdfLUT, vec2(NdotV, roughness)).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

    return (kD * diffuse + specular) * ao;
}
