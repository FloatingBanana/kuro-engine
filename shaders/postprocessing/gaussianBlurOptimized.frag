#pragma language glsl3

uniform vec2 direction;

vec4 GaussianBlurOptimized(sampler2D tex, vec2 texcoords, vec2 direction);
#pragma include "engine/shaders/utils/incl_blur.glsl"

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return GaussianBlurOptimized(tex, texcoords, direction);
}