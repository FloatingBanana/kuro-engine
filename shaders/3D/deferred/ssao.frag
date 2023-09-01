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


vec3 ReconstructPosition(vec2 uv, float depth, mat4 invProj) {
    float x = uv.x * 2.0 - 1.0;
    float y = (1.0 - uv.y) * 2.0 - 1.0;
    float z = depth * 2.0 - 1.0;

    vec4 position_s = vec4(x, y, z, 1.0);
    vec4 position_v = invProj * position_s;
    
    return position_v.xyz / position_v.w;
}

vec3 ReconstructPosition(vec2 uv, sampler2D depthBuffer, mat4 invProj) {
    return ReconstructPosition(uv, texture2D(depthBuffer, uv).r, invProj);
}


vec3 ReconstructNormal(sampler2D depthBuffer, vec2 uv, mat4 invProj) {
    vec2 texelSize = 1.0 / textureSize(depthBuffer, 0);
    float depth = texture2D(depthBuffer, uv).r;
    vec3 viewSpacePos_c = ReconstructPosition(uv, depthBuffer, invProj);

    vec4 H = vec4(
        texture2D(depthBuffer, uv + vec2(-1.0, 0.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2( 1.0, 0.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2(-2.0, 0.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2( 2.0, 0.0) * texelSize).r
    );

    vec4 V = vec4(
        texture2D(depthBuffer, uv + vec2(0.0,-1.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2(0.0, 1.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2(0.0,-2.0) * texelSize).r,
        texture2D(depthBuffer, uv + vec2(0.0, 2.0) * texelSize).r
    );
    
    vec3 viewSpacePos_l = ReconstructPosition(uv + vec2(-1.0, 0.0) * texelSize, H.x, invProj);
    vec3 viewSpacePos_r = ReconstructPosition(uv + vec2( 1.0, 0.0) * texelSize, H.y, invProj);
    vec3 viewSpacePos_d = ReconstructPosition(uv + vec2( 0.0,-1.0) * texelSize, V.x, invProj);
    vec3 viewSpacePos_u = ReconstructPosition(uv + vec2( 0.0, 1.0) * texelSize, V.y, invProj);

    vec3 l = viewSpacePos_c - viewSpacePos_l;
    vec3 r = viewSpacePos_r - viewSpacePos_c;
    vec3 d = viewSpacePos_c - viewSpacePos_d;
    vec3 u = viewSpacePos_u - viewSpacePos_c;

    vec2 he = abs(H.xy * H.zw * (1.0 / (2.0 * H.zw - H.xy)) - depth);
    vec2 ve = abs(V.xy * V.zw * (1.0 / (2.0 * V.zw - V.xy)) - depth);

    vec3 hDeriv = he.x < he.y ? l : r;
    vec3 vDeriv = ve.x < ve.y ? d : u;

    return normalize(cross(hDeriv, vDeriv)) * -1.0;
}


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
        vec3 samplePos = tbn * u_samples[i];
        samplePos = fragPos + samplePos * u_kernelRadius;

        vec4 offset = vec4(samplePos, 1.0);
        offset = u_projection * offset;
        offset.y *= -1.0;
        offset.xyz /= offset.w;
        offset.xyz = offset.xyz * 0.5 + 0.5;

        vec3 samplePosView;
#       if defined(SAMPLE_DEPTH_ACCURATE) || defined(SAMPLE_DEPTH_NAIVE)
            samplePosView = ReconstructPosition(offset.xy, u_depthBuffer, u_invProjection);
#       else
            vec4 wSamplePosView = texture2D(u_gPosition, offset.xy);
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