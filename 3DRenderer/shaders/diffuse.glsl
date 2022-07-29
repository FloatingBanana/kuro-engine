varying highp vec3 VertexNormal;

#ifdef VERTEX
uniform mat4 u_world;
uniform mat4 u_view;
uniform mat4 u_proj;

vec4 position(mat4 transformProjection, vec4 position) {
    return u_proj * u_view * u_world * position;
}
#endif

#ifdef PIXEL
uniform vec3 u_ambientColor;
uniform vec3 u_diffuseColor;
uniform vec3 u_specularColor;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    return vec4(u_ambientColor * u_diffuseColor * u_specularColor, 1);
}
#endif