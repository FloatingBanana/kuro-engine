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


/////////////////////
// Blur algorithms //
/////////////////////

vec4 BoxBlur(sampler2D tex, vec2 texCoord, int kernelSize) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0));
    vec4 result = vec4(0);

    for (int x = -kernelSize; x < kernelSize; x++) {
        for (int y = -kernelSize; y < kernelSize; y++) {
            vec2 offset = vec2(x, y) * texelSize;
            result += texture2D(tex, texCoord + offset);
        }
    }

    return result / vec4(kernelSize*2*kernelSize*2);
}


float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

vec4 GaussianBlur(sampler2D tex, vec2 texcoords, vec2 direction) {
    vec2 tex_offset = 1.0 / textureSize(tex, 0);
    vec4 result = texture2D(tex, texcoords) * weight[0];

    for(int i = 1; i < 5; ++i) {
        vec2 dir = direction * tex_offset * i;

        result += texture2D(tex, texcoords + dir) * weight[i];
        result += texture2D(tex, texcoords - dir) * weight[i];
    }

    return result;
}



// https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
float offset[3] = float[] (0.0, 1.3846153846, 3.2307692308);
float weight2[3] = float[] (0.2270270270, 0.3162162162, 0.0702702703);

vec4 GaussianBlurOptimized(sampler2D tex, vec2 texcoords, vec2 direction) {
    vec2 tex_offset = 1.0 / textureSize(tex, 0);
    vec4 result = texture2D(tex, texcoords) * weight2[0];

    for(int i = 1; i < 3; ++i) {
        vec2 dir = direction * tex_offset * offset[i];

        result += texture2D(tex, texcoords + dir) * weight2[i];
        result += texture2D(tex, texcoords - dir) * weight2[i];
    }

    return result;
}