#pragma language glsl3

#define UVtoNDC(uv) (vec3(uv.x, 1.0 - uv.y, uv.z) * 2.0 - 1.0)
#define NDCtoUV(ndc) (ndc * vec3(0.5, -0.5, 0.5) + 0.5)

vec3 ProjectUV(vec3 position, mat4 proj) {
    vec4 clipPos = proj * vec4(position, 1.0);

    return NDCtoUV(clipPos.xyz / clipPos.w);
}


vec3 ReconstructPosition(vec2 uv, float depth, mat4 invProj) {
    vec4 pos = invProj * vec4(UVtoNDC(vec3(uv, depth)), 1.0);

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
vec3 ReconstructNormal(sampler2D depthBuffer, vec2 uv, mat4 invProj) {
    vec3 _p;
    return ReconstructNormal(depthBuffer, uv, invProj, _p);
}


float LinearizeDepth(float depth, float near, float far) {
    depth = depth * 2.0 - 1.0;
    return -((far * near) / (far + depth * (near-far)));
}

const vec2 invAtan = 1.0 / vec2(TAU, PI);
vec2 EncodeSphericalMap(vec3 dir) {
    return vec2(atan(dir.z, dir.x), asin(dir.y)) * invAtan + 0.5;
}

vec3 DecodeSphericalMap(vec2 uv) {
    uv = (uv - 0.5) / invAtan;
    return vec3(cos(uv.x) * cos(uv.y), sin(uv.y), sin(uv.x) * cos(uv.y));
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

// https://github.com/PanosK92/SpartanEngine/blob/master/data/shaders/common.hlsl#L529
float ScreenFade(vec2 uv) {
    vec2 fade = max(vec2(0.0), 12.0 * abs(uv - 0.5) - 5.0);
    return clamp(1.0 - dot(fade, fade), 0.0, 1.0);
}

// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
const vec3 ignmagic = vec3(52.9829189, 0.06711056, 0.00583715);
float NoiseIGN(vec2 pos) {
    return mod(ignmagic.x * dot(pos, ignmagic.yz), 1.0);
}

// https://github.com/PanosK92/SpartanEngine/blob/master/data/shaders/common.hlsl#L462
float Random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

#define Saturate(v) (clamp(v, 0.0, 1.0))

bool IsSaturated(float v) {
    return v >= 0.0 && v <= 1.0;
}
bool IsSaturated(vec2 v) {
    return IsSaturated(v.x) && IsSaturated(v.y);
}
bool IsSaturated(vec3 v) {
    return IsSaturated(v.x) && IsSaturated(v.y) && IsSaturated(v.z);
}
bool IsSaturated(vec4 v) {
    return IsSaturated(v.x) && IsSaturated(v.y) && IsSaturated(v.z) && IsSaturated(v.w);
}


mat3 GetTBNMatrix(mat4 world, vec3 normal, vec3 tangent) {
    vec3 T = normalize(vec3(world * vec4(tangent, 0.0)));
    vec3 N = normalize(vec3(world * vec4(normal,  0.0)));
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);

    return mat3(T, B, N);
}