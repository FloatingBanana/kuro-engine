#pragma language glsl3

vec4 BoxBlur(sampler2D tex, vec2 texCoord, int kernelSize) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0));
    vec4 result = vec4(0);

    for (int x = -kernelSize; x < kernelSize; x++) {
        for (int y = -kernelSize; y < kernelSize; y++) {
            vec2 offset = vec2(x, y) * texelSize;
            result += texture(tex, texCoord + offset);
        }
    }

    return result / vec4(kernelSize*2*kernelSize*2);
}

#ifndef INCLUDED
uniform int size;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return BoxBlur(tex, texcoords, size);
}
#endif