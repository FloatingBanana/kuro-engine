// https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
vec3 Downsample(sampler2D tex, vec2 texcoords) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0) / 2);
    float x = texelSize.x;
    float y = texelSize.y;

    // Take 13 samples around current texel:
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(tex, vec2(texcoords.x - 2.0*x, texcoords.y + 2.0*y)).rgb;
    vec3 b = texture(tex, vec2(texcoords.x,         texcoords.y + 2.0*y)).rgb;
    vec3 c = texture(tex, vec2(texcoords.x + 2.0*x, texcoords.y + 2.0*y)).rgb;

    vec3 d = texture(tex, vec2(texcoords.x - 2.0*x, texcoords.y)).rgb;
    vec3 e = texture(tex, vec2(texcoords.x,         texcoords.y)).rgb;
    vec3 f = texture(tex, vec2(texcoords.x + 2.0*x, texcoords.y)).rgb;

    vec3 g = texture(tex, vec2(texcoords.x - 2.0*x, texcoords.y - 2.0*y)).rgb;
    vec3 h = texture(tex, vec2(texcoords.x,         texcoords.y - 2.0*y)).rgb;
    vec3 i = texture(tex, vec2(texcoords.x + 2.0*x, texcoords.y - 2.0*y)).rgb;

    vec3 j = texture(tex, vec2(texcoords.x - x, texcoords.y + y)).rgb;
    vec3 k = texture(tex, vec2(texcoords.x + x, texcoords.y + y)).rgb;
    vec3 l = texture(tex, vec2(texcoords.x - x, texcoords.y - y)).rgb;
    vec3 m = texture(tex, vec2(texcoords.x + x, texcoords.y - y)).rgb;

    // Apply weighted distribution:
    // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1
    // a,b,d,e * 0.125
    // b,c,e,f * 0.125
    // d,e,g,h * 0.125
    // e,f,h,i * 0.125
    // j,k,l,m * 0.5
    // This shows 5 square areas that are being sampled. But some of them overlap,
    // so to have an energy preserving downsample we need to make some adjustments.
    // The weights are the distributed, so that the sum of j,k,l,m (e.g.)
    // contribute 0.5 to the final color output. The code below is written
    // to effectively yield this sum. We get:
    // 0.125*5 + 0.03125*4 + 0.0625*4 = 1
    vec3 downsample = e*0.125;
    downsample += (a+c+g+i)*0.03125;
    downsample += (b+d+f+h)*0.0625;
    downsample += (j+k+l+m)*0.125;

    return downsample;
}


#ifndef INCLUDED
#pragma language glsl3

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return vec4(Downsample(tex, texcoords), 1.0);
}

#endif