varying vec2 v_texCoords;

#ifdef VERTEX
attribute vec2 VertexTexCoords;
attribute vec3 VertexNormal;

uniform mat4 u_world;
uniform mat4 u_viewProj;
uniform bool u_isCanvasEnabled;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 worldPos = u_world * position;
    vec4 screen = u_viewProj * worldPos;

    // Assigning outputs
    v_texCoords = VertexTexCoords;

    // LÖVE flips meshes upside down when drawing to a canvas, we need to flip them back
    if (u_isCanvasEnabled)
        screen.y *= -1.0;

    return screen;
}
#endif

#ifdef PIXEL
uniform sampler2D u_diffuseTexture;
uniform float u_strenght;

void effect() {
    gl_FragColor = Texel(u_diffuseTexture, v_texCoords) * u_strenght;
}
#endif