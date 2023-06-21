#pragma language glsl3
#define KERNEL_SIZE 32
#define KERNEL_RADIUS 0.5

uniform sampler2D u_gPosition;
uniform sampler2D u_gNormal;
uniform sampler2D u_gAlbedoSpec;
uniform sampler2D u_noiseTex;

uniform vec3 u_samples[KERNEL_SIZE];
uniform mat4 u_view;
uniform mat4 u_projection;

const vec2 noiseScale = vec2(800.0/4.0, 600.0/4.0);

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec4 wFragPos = texture2D(u_gPosition, texcoords);
    vec3 fragPos = (u_view * wFragPos).xyz;
    vec3 normal = mat3(u_view) * texture2D(u_gNormal, texcoords).rgb;
    vec3 randomVec = vec3(texture2D(u_noiseTex, texcoords * noiseScale).xy * 2 - 1, 0);

    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 tbn = mat3(tangent, bitangent, normal);

    const float bias = 0.025;
    float occlusion = 0.0;
    for (int i = 0; i < KERNEL_SIZE; i++) {
        vec3 samplePos = tbn * u_samples[i];
        samplePos = fragPos + samplePos * KERNEL_RADIUS;

        vec4 offset = vec4(samplePos, 1.0);
        offset = u_projection * offset;
        offset.y *= -1.0;
        offset.xyz /= offset.w;
        offset.xyz = offset.xyz * 0.5 + 0.5;

        vec4 wSample = texture2D(u_gPosition, offset.xy);
        float sampleDepth = (u_view * wSample).z;
        float rangeCheck = smoothstep(0.0, 1.0, KERNEL_RADIUS / abs(fragPos.z - sampleDepth));

        float backFilter = (wFragPos.xyz == vec3(0) || wSample.xyz == vec3(0)) ? 0.0 : 1.0; // Discards background pixels
        occlusion += (sampleDepth >= samplePos.z + bias) ? rangeCheck * backFilter : 0.0;
    }

    occlusion = pow(occlusion / KERNEL_SIZE, 1);
    return vec4(1.0 - occlusion);
}