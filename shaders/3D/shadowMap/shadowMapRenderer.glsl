varying vec3 v_normal;

#ifdef VERTEX
attribute vec3 VertexNormal;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat3 u_invTranspWorld;

vec4 position(mat4 transformProjection, vec4 position) {
    v_normal = VertexNormal * u_invTranspWorld;

    return u_viewProj * u_world * position;
}
#endif

#ifdef PIXEL
uniform vec3 lightDir;

void effect() {
    float bias = max(0.05 * (1.0 - dot(lightDir, v_normal)), 0.005);
    gl_FragDepth = gl_FragCoord.z + (gl_FrontFacing ? bias : 0.0);
}
#endif