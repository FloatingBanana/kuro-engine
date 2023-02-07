// https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
uniform vec2 direction;
uniform vec2 texSize;
float offset[3] = float[] (0.0, 1.3846153846, 3.2307692308);
float weight[3] = float[] (0.2270270270, 0.3162162162, 0.0702702703);

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec2 tex_offset = 1.0 / texSize;
    vec3 result = Texel(texture, texcoords).rgb * weight[0];

    for(int i = 1; i < 3; ++i) {
        vec2 dir = direction * tex_offset * offset[i];

        result += Texel(texture, texcoords + dir).rgb * weight[i];
        result += Texel(texture, texcoords - dir).rgb * weight[i];
    }

    return vec4(result, 1.0);
}