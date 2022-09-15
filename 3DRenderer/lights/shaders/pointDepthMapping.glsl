varying vec4 v_fragPos;

#ifdef VERTEX
uniform mat4 u_viewProj;
uniform mat4 u_world;

vec4 position(mat4 transformProjection, vec4 position) {
    v_fragPos = u_world * position;

    return u_viewProj * v_fragPos;
}
#endif

#ifdef PIXEL
uniform vec3 lightPos;
uniform float farPlane;

void effect() {
    gl_FragDepth = length(v_fragPos.xyz - lightPos) / farPlane;
}
#endif