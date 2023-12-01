#pragma language glsl3
#define FragColor love_Canvases[0]
#define Velocity love_Canvases[1]

varying vec3 v_texCoords;
varying vec4 v_clipPos;
varying vec4 v_prevClipPos;

#ifdef VERTEX
uniform mat4 u_viewProj;
uniform mat4 u_prevViewProj;

vec4 position(mat4 _, vec4 position) {
    vec4 screen = u_viewProj * position;
    
    v_texCoords = position.xyz;
    v_clipPos = screen;
    v_prevClipPos = u_prevViewProj * position;

    screen.y *= -1.0;
    return screen.xyww;
}
#endif

#ifdef PIXEL
uniform samplerCube u_skyTex;

vec2 EncodeVelocity(vec2 vel);
#pragma include "engine/shaders/incl_utils.glsl"

void effect() {
    vec2 vel = (v_clipPos.xy / v_clipPos.w) - (v_prevClipPos.xy / v_prevClipPos.w);

    FragColor = texture(u_skyTex, v_texCoords);
    Velocity = vec4(EncodeVelocity(vel), 0, 1);
}
#endif