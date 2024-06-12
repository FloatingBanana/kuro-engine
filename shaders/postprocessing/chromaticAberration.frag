vec3 ChromaticAberration(vec3 color, vec3 offset) {
    return vec3(
        texture(texture, texcoords + offset).r,
        texture(texture, texcoords + offset).g,
        texture(texture, texcoords + offset).b,
    );
}

#ifndef INCLUDED
uniform vec2 u_offset;
    
vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec4 pixel = texture(texture, texcoords);
    return vec4(ChromaticAberration(pixek.rgb, u_offset), pixel.a);
}
#endif