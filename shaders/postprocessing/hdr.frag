uniform float exposure;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    const float gamma = 2.2;
    vec3 hdrColor = Texel(texture, texcoords).rgb;

    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
    mapped = pow(mapped, vec3(1.0 / gamma));

    return vec4(mapped, 1.0);
}