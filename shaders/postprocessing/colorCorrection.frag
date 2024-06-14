#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

#define SATURATE(v) clamp(v, 0.0, 1.0)

vec3 ColorCorrection(vec3 color, vec3 colorFilter, float contrast, float brightness, float exposure, float saturation) {
    color = SATURATE(color * colorFilter);
    color = SATURATE(((color - 0.5) * contrast) + 0.5);
    color = SATURATE(color + brightness);
    color = SATURATE(color * exposure);

    // Saturation
    vec3 grayscale = vec3(Luminance(color));
    color = SATURATE(mix(grayscale, color, saturation));

    return color;
}

#ifndef INCLUDED

uniform vec3  u_filter;
uniform float u_contrast;
uniform float u_brightness;
uniform float u_exposure;
uniform float u_saturation;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 pixel = ColorCorrection(texture(tex, texcoords).rgb, u_filter, u_contrast, u_brightness, u_exposure, u_saturation);
    return vec4(pixel, 1.0);
}
#endif