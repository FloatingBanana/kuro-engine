#pragma language glsl3

uniform int size;

vec4 BoxBlur(sampler2D tex, vec2 texcoords, int kernelSize);
#pragma include "engine/shaders/utils/incl_blur.glsl"

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return BoxBlur(tex, texcoords, size);
}