#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"

uniform sampler2D u_noiseTex;
uniform vec3 u_samples[64];
uniform vec2 u_noiseScale;
uniform int u_kernelSize;
uniform float u_kernelRadius;

const float depthBias = 0.025;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 fragPos;
    vec3 normal = ReconstructNormal(uDepthBuffer, texcoords, uInvProjMatrix, fragPos);
    vec3 randomVec = vec3(texture(u_noiseTex, texcoords * u_noiseScale).xy * 2.0 - 1.0, 0.0);

    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 tbn = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
    for (int i = 0; i < u_kernelSize; i++) {
        vec3 samplePos = fragPos + (tbn * u_samples[i] * u_kernelRadius);
        vec2 offset = ProjectUV(samplePos, uProjMatrix).xy;

        float sampleDepth = LinearizeDepth(texture(uDepthBuffer, offset).r, uNearPlane, uFarPlane);
        float rangeCheck = smoothstep(0.0, 1.0, u_kernelRadius / abs(fragPos.z - sampleDepth));

        occlusion += (sampleDepth >= samplePos.z + depthBias) ? rangeCheck : 0.0;
    }

    occlusion = pow(occlusion / u_kernelSize, 1);
    return vec4(1.0 - occlusion);
}