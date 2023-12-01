#pragma language glsl3

uniform vec2 direction;

vec4 GaussianBlur(sampler2D tex, vec2 texcoords, vec2 direction);
#pragma include "engine/shaders/incl_utils.glsl"

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return GaussianBlur(tex, texcoords, direction);
}