#pragma language glsl3

#ifdef VERTEX
uniform mat4 u_viewProj;
out vec3 v_texCoords;

vec4 position(mat4 _, vec4 position) {
    vec4 screen = u_viewProj * position;    

    v_texCoords = position.xyz;
    screen.y *= -1.0;

    return screen.xyww;
}
#endif

#ifdef PIXEL
in vec3 v_texCoords;
uniform samplerCube u_skyTex;

vec4 effect(EFFECTARGS) {
    return texture(u_skyTex, v_texCoords);
}
#endif