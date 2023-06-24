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