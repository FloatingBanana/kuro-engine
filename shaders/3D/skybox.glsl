varying vec3 texCoords;

#ifdef VERTEX
uniform mat4 viewProj;

vec4 position(mat4 _, vec4 position) {
    texCoords = position.xyz;
    vec4 screen = viewProj * position;

    screen.y *= -1.0;
    return screen;
}
#endif

#ifdef PIXEL
uniform samplerCube skyTex;

vec4 effect(vec4 _0, sampler2D _1, vec2 _2, vec2 _3) {
    return Texel(skyTex, texCoords);
}
#endif