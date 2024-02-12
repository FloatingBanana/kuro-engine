#pragma language glsl3

// https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
const float offset[3] = float[] (0.0, 1.3846153846, 3.2307692308);
const float weight2[3] = float[] (0.2270270270, 0.3162162162, 0.0702702703);

vec4 GaussianBlurOptimized(sampler2D tex, vec2 texcoords, vec2 direction) {
    vec2 tex_offset = 1.0 / textureSize(tex, 0);
    vec4 result = texture(tex, texcoords) * weight2[0];

    for(int i = 1; i < 3; ++i) {
        vec2 dir = direction * tex_offset * offset[i];

        result += texture(tex, texcoords + dir) * weight2[i];
        result += texture(tex, texcoords - dir) * weight2[i];
    }

    return result;
}

#ifndef INCLUDED
uniform vec2 direction;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return GaussianBlurOptimized(tex, texcoords, direction);
}
#endif