#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform int size;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return BoxBlur(tex, texcoords, size);
}