vec3 ProjectUV(vec3 position, mat4 proj) {
    vec4 clipPos = proj * vec4(position, 1.0);
    vec3 screen = (clipPos.xyz / clipPos.w) * vec3(0.5, -0.5, 0.5) + 0.5;

    return screen;
}


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


float LinearizeDepth(float depth, float near, float far) {
    float z = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near + z * (far - near)) / far;
}


#ifndef VELOCITY_ENCODE_PRECISION
#   define VELOCITY_ENCODE_PRECISION 3.0
#endif

vec2 EncodeVelocity(vec2 vel) {
    return pow(vel * 0.5 + 0.5, vec2(VELOCITY_ENCODE_PRECISION));
}

vec2 DecodeVelocity(vec2 vel) {
    return pow(vel, vec2(1.0 / VELOCITY_ENCODE_PRECISION)) * 2.0 - 1.0;
}


const vec3 lumFactor = vec3(0.299, 0.587, 0.114);

float Luminance(vec3 color) {
    return dot(color, lumFactor);
}

float LuminanceGamma(vec3 color) {
    return sqrt(dot(color, lumFactor));
}


bool Check01Range(float v) {
    return v >= 0.0 && v <= 1.0;
}

bool Check01Range(vec2 v) {
    return Check01Range(v.x) && Check01Range(v.y);
}


mat3 GetTBNMatrix(mat4 world, vec3 normal, vec3 tangent) {
    vec3 T = normalize(vec3(world * vec4(tangent, 0.0)));
    vec3 N = normalize(vec3(world * vec4(normal,  0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);

    return mat3(T, B, N);
}


#ifndef MAX_BONE_COUNT
#   define MAX_BONE_COUNT 50
#endif

mat4 GetSkinningMatrix(mat4 boneMatrices[MAX_BONE_COUNT], vec4 boneIDs, vec4 weights) {
    mat4 boneTransform = mat4(0);
    bool hasBones = false;

    for (int i=0; i < 4; i++) {
        if (boneIDs[i] < 0)
            continue;
        if (boneIDs[i] >= MAX_BONE_COUNT) {
            hasBones = false;
            break;
        }

        boneTransform += boneMatrices[int(boneIDs[i])] * weights[i];
        hasBones = true;
    }

    if (hasBones)
        return boneTransform;
        
    return mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1
    );
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


const float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

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
const float offset[3] = float[] (0.0, 1.3846153846, 3.2307692308);
const float weight2[3] = float[] (0.2270270270, 0.3162162162, 0.0702702703);

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