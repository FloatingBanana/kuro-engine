#pragma language glsl3

//#define SAMPLE_DEPTH_ACCURATE

uniform sampler2D u_gPosition;
uniform sampler2D u_gNormal;
uniform sampler2D u_gAlbedoSpec;
uniform sampler2D u_noiseTex;
uniform sampler2D u_depthBuffer;

uniform vec3 u_samples[64];
uniform mat4 u_view;
uniform mat4 u_projection;
uniform mat4 u_invProjection;
uniform vec2 u_noiseScale;
uniform int u_kernelSize;
uniform float u_kernelRadius;

const float depthBias = 0.025;


vec3 ReconstructPosition(vec2 uv, sampler2D depthBuffer, mat4 invProj);
vec3 ReconstructNormal(sampler2D depthBuffer, vec2 uv, mat4 invProj);
#pragma include "engine/shaders/incl_utils.glsl"


vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 randomVec = vec3(texture2D(u_noiseTex, texcoords * u_noiseScale).xy * 2.0 - 1.0, 0);
    vec3 fragPos;
    vec3 normal;

#   if defined(SAMPLE_DEPTH_ACCURATE)
        // Better quality
        fragPos = ReconstructPosition(texcoords, u_depthBuffer, u_invProjection);
        normal = ReconstructNormal(u_depthBuffer, texcoords, u_invProjection);
#   elif defined(SAMPLE_DEPTH_NAIVE)
        // Better peformance
        fragPos = ReconstructPosition(texcoords, u_depthBuffer, u_invProjection);
        normal = normalize(cross(dFdy(fragPos), dFdx(fragPos)));
#   else
        // For deferred rendering (best peformance and perfect accuracy)
        vec4 wFragPos = texture2D(u_gPosition, texcoords);
        if (wFragPos.xyz == vec3(0)) return vec4(0);

        fragPos = (u_view * wFragPos).xyz;
        normal = mat3(u_view) * texture2D(u_gNormal, texcoords).xyz;
#   endif

    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 tbn = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
    for (int i = 0; i < u_kernelSize; i++) {
        vec3 samplePos = fragPos + (tbn * u_samples[i] * u_kernelRadius);
        vec2 offset = ProjectUV(samplePos, u_projection).xy;
        vec3 samplePosView;

#       if defined(SAMPLE_DEPTH_ACCURATE) || defined(SAMPLE_DEPTH_NAIVE)
            samplePosView = ReconstructPosition(offset, u_depthBuffer, u_invProjection);
#       else
            vec4 wSamplePosView = texture2D(u_gPosition, offset);
            if (wSamplePosView.xyz == vec3(0)) continue;

            samplePosView = (u_view * wSamplePosView).xyz;
#       endif

        float sampleDepth = samplePosView.z;
        float rangeCheck = smoothstep(0.0, 1.0, u_kernelRadius / abs(fragPos.z - sampleDepth));

        occlusion += (sampleDepth >= samplePos.z + depthBias) ? rangeCheck : 0.0;
    }

    occlusion = pow(occlusion / u_kernelSize, 1);
    return vec4(1.0 - occlusion);
}