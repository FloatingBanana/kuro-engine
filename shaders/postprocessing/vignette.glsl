float Vignette(vec2 uv, float intensity, float power) {
    uv *=  1.0 - uv.yx;
    
    float vig = uv.x*uv.y * intensity;

    return min(pow(vig, power), 1);
}

#ifndef INCLUDED
uniform vec4 u_color;
uniform float u_intensity;
uniform float u_power;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec4 pixel = Texel(tex, texcoords) * color;
    float vig = Vignette(texcoords, u_intensity, u_power);
    
    return mix(u_color, pixel, vig);
}
#endif