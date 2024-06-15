#pragma language glsl3

vec3 ProjectUV(vec3 position, mat4 proj) {
    vec4 clipPos = proj * vec4(position, 1.0);
    vec3 screen = (clipPos.xyz / clipPos.w) * vec3(0.5, -0.5, 0.5) + 0.5;

    return screen;
}


vec3 ReconstructPosition(vec2 uv, float depth, mat4 invProj) {
    float x = uv.x * 2.0 - 1.0;
    float y = (1.0 - uv.y) * 2.0 - 1.0;
    float z = depth * 2.0 - 1.0;
    vec4 pos = invProj * vec4(x, y, z, 1.0);

    return pos.xyz / pos.w;
}

vec3 ReconstructPosition(vec2 uv, sampler2D depthBuffer, mat4 invProj) {
    return ReconstructPosition(uv, texture(depthBuffer, uv).r, invProj);
}


vec3 ReconstructNormal(sampler2D depthBuffer, vec2 uv, mat4 invProj, out vec3 position) {
    vec2 texelSize = 1.0 / textureSize(depthBuffer, 0);
    float depth = texture(depthBuffer, uv).r;
    vec3 viewSpacePos_c = ReconstructPosition(uv, depthBuffer, invProj);
    position = viewSpacePos_c;

    vec4 H = vec4(
        texture(depthBuffer, uv + vec2(-1.0, 0.0) * texelSize).r,
        texture(depthBuffer, uv + vec2( 1.0, 0.0) * texelSize).r,
        texture(depthBuffer, uv + vec2(-2.0, 0.0) * texelSize).r,
        texture(depthBuffer, uv + vec2( 2.0, 0.0) * texelSize).r
    );

    vec4 V = vec4(
        texture(depthBuffer, uv + vec2(0.0,-1.0) * texelSize).r,
        texture(depthBuffer, uv + vec2(0.0, 1.0) * texelSize).r,
        texture(depthBuffer, uv + vec2(0.0,-2.0) * texelSize).r,
        texture(depthBuffer, uv + vec2(0.0, 2.0) * texelSize).r
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
    depth = depth * 2.0 - 1.0;
    return -((far * near) / (far + depth * (near-far)));
}

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 EncodeNormal(vec3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    n.xy = n.z >= 0.0 ? n.xy : ((1.0 - abs(n.yx)) * sign(n.xy));
    return n.xy * 0.5 + 0.5;
}
vec3 DecodeNormal(vec2 f) {
    f = f * 2.0 - 1.0;    
    vec3 n = vec3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = max(-n.z, 0.0);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;

    return normalize(n);
}


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
        
    return mat4(1.0);
}