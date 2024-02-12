#pragma language glsl3

const float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

vec4 GaussianBlur(sampler2D tex, vec2 texcoords, vec2 direction) {
    vec2 tex_offset = 1.0 / textureSize(tex, 0);
    vec4 result = texture(tex, texcoords) * weight[0];

    for(int i = 1; i < 5; ++i) {
        vec2 dir = direction * tex_offset * i;

        result += texture(tex, texcoords + dir) * weight[i];
        result += texture(tex, texcoords - dir) * weight[i];
    }

    return result;
}


#ifndef INCLUDED
uniform vec2 direction;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return GaussianBlur(tex, texcoords, direction);
}
#endif