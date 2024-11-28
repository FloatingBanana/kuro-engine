#pragma language glsl3

#pragma include "engine/shaders/3D/misc/incl_PBRLighting.glsl"

vec2 Hammersley(uint i, uint N) {
    // Van Der Corput sequence
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float vdc =  float(bits) * 2.3283064365386963e-10;

    return vec2(float(i) / float(N), vdc);
}



vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness) {
    float a = roughness*roughness;

    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    // spherical to cartesian
    vec3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;

    // tangent to world
    vec3 up = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);

    vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}


float GeometrySchlickGGX_IBL(float NdotV, float roughness) {
    float r = roughness;
    float k = (r*r) * 0.5;
    float denom = NdotV * (1.0 - k) + k;
    
    return NdotV / denom;
}


float GeometrySmith_IBL(float NdotV, float NdotL, float roughness) {
    float ggx2 = GeometrySchlickGGX_IBL(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX_IBL(NdotL, roughness);

    return ggx1 * ggx2;
}



#ifndef BRDF_SAMPLE_COUNT
#   define BRDF_SAMPLE_COUNT 1024
#endif

vec2 integrateBRDF(float NdotV, float roughness) {
    vec3 V;
    V.x = sqrt(1.0 - NdotV*NdotV);
    V.y = 0.0;
    V.z = NdotV;

    vec3 N = vec3(0.0, 0.0, 1.0);
    float A = 0.0;
    float B = 0.0;

    for (uint i = 0u; i < uint(BRDF_SAMPLE_COUNT); ++i) {
        vec2 Xi = Hammersley(i, uint(BRDF_SAMPLE_COUNT));
        vec3 H = ImportanceSampleGGX(Xi, N, roughness);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(L.z, 0.0);
        float NdotH = max(H.z, 0.0);
        float VdotH = max(dot(V, H), 0.0);

        if (NdotL > 0.0) {
            float G = GeometrySmith_IBL(dot(N, V), dot(N, L), roughness);
            float G_Vis = (G * VdotH) / (NdotH * NdotV);
            float Fc = pow(1.0 - VdotH, 5.0);

            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }

    return vec2(A, B) / BRDF_SAMPLE_COUNT;
}



#ifndef IRRADIANCE_SAMPLE_DELTA
#   define IRRADIANCE_SAMPLE_DELTA 0.025
#endif

vec3 CalculateIrradiance(samplerCube environment, vec3 normal) {
    vec3 right = normalize(cross(vec3(0.0,1.0,0.0), normal));
    vec3 up = normalize(cross(normal, right));

    vec3 irradiance = vec3(0.0);
    float sampleCount = 0.0;
    
    for (float phi = 0.0; phi < TAU; phi += IRRADIANCE_SAMPLE_DELTA) {
        for(float theta = 0.0; theta < HALF_PI; theta += IRRADIANCE_SAMPLE_DELTA) {
            vec3 tangentSample = vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal;

            irradiance += texture(environment, sampleVec).rgb * cos(theta) * sin(theta);
            sampleCount++;
        }
    }

    return PI * irradiance / sampleCount;
}



#ifndef ENVIRONMENT_RADIANCE_SAMPLE_COUNT
#   define ENVIRONMENT_RADIANCE_SAMPLE_COUNT 1024
#endif

vec3 CalculateEnvironmentRadiance(samplerCube environment, vec3 N, float roughness) {
    vec3 R = N;
    vec3 V = N;

    float resolution = textureSize(environment, 0).x;
    float saTexel = 4.0 * PI / (6.0 * resolution * resolution);

    vec3 prefilteredColor = vec3(0.0);
    float totalWeight = 0.0;

    for (uint i = 0u; i < uint(ENVIRONMENT_RADIANCE_SAMPLE_COUNT); ++i) {
        vec2 Xi = Hammersley(i, uint(ENVIRONMENT_RADIANCE_SAMPLE_COUNT));
        vec3 H = ImportanceSampleGGX(Xi, N, roughness);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(dot(N, L), 0.0);
        if (NdotL > 0.0) {
            float HdotV = max(dot(H, V), 0.0);
            float NdotH = max(dot(N, H), 0.0);
            float D = DistributionGGX(NdotH, roughness);
            float pdf = (D * NdotH / (4.0 * HdotV)) + 0.0001;

            float saSample = 1.0 / (float(ENVIRONMENT_RADIANCE_SAMPLE_COUNT) * pdf);
            float mipLevel = (roughness == 0.0) ? 0.0 : 0.5 * log2(saSample / saTexel);

            prefilteredColor += textureLod(environment, L, mipLevel).rgb * NdotL;
            totalWeight += NdotL;
        }
    }

    return prefilteredColor / totalWeight;
}