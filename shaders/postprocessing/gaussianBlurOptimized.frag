#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform vec2 direction;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return GaussianBlurOptimized(tex, texcoords, direction);
}