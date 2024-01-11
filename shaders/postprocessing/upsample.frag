// https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
vec3 Upsample(sampler2D tex, vec2 texcoords, float filterRadius) {
    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.
    float x = filterRadius;
    float y = filterRadius;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(tex, vec2(texcoords.x - x, texcoords.y + y)).rgb;
    vec3 b = texture(tex, vec2(texcoords.x,     texcoords.y + y)).rgb;
    vec3 c = texture(tex, vec2(texcoords.x + x, texcoords.y + y)).rgb;

    vec3 d = texture(tex, vec2(texcoords.x - x, texcoords.y)).rgb;
    vec3 e = texture(tex, vec2(texcoords.x,     texcoords.y)).rgb;
    vec3 f = texture(tex, vec2(texcoords.x + x, texcoords.y)).rgb;

    vec3 g = texture(tex, vec2(texcoords.x - x, texcoords.y - y)).rgb;
    vec3 h = texture(tex, vec2(texcoords.x,     texcoords.y - y)).rgb;
    vec3 i = texture(tex, vec2(texcoords.x + x, texcoords.y - y)).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    vec3 upsample = e*4.0;
    upsample += (b+d+f+h)*2.0;
    upsample += (a+c+g+i);
    upsample *= 1.0 / 16.0;

    return upsample;
}


#ifndef INCLUDED
#pragma language glsl3
uniform float u_filterRadius;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return vec4(Upsample(tex, texcoords, u_filterRadius), 1.0);
}

#endif