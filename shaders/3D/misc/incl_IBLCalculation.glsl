#pragma language glsl3

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
    float k = (r*r) * 0.5;// / 2.0;
    float denom = NdotV * (1.0 - k) + k;
    
    return NdotV / denom;
}


float GeometrySmith_IBL(float NdotV, float NdotL, float roughness) {
    float ggx2 = GeometrySchlickGGX_IBL(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX_IBL(NdotL, roughness);

    return ggx1 * ggx2;
}