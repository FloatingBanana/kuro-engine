uniform vec2 direction;
uniform vec2 texSize;
float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec2 tex_offset = 1.0 / texSize;
    vec3 result = Texel(texture, texcoords).rgb * weight[0];

    for(int i = 1; i < 5; ++i) {
        vec2 dir = direction * tex_offset * i;

        result += Texel(texture, texcoords + dir).rgb * weight[i];
        result += Texel(texture, texcoords - dir).rgb * weight[i];
    }

    return vec4(result, 1.0);
}