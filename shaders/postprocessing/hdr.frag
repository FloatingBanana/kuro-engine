uniform float exposure;
uniform sampler2D bloomBlur;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 hdrColor = (Texel(texture, texcoords) + Texel(bloomBlur, texcoords)).rgb;
    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);

    return vec4(mapped, 1.0);
}