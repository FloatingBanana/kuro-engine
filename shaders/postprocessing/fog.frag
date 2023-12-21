#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform vec2 u_minMaxDistance;
uniform vec3 u_fogColor;
uniform sampler2D u_depthBuffer;
uniform mat4 u_invViewProj;
uniform vec3 u_viewPos;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 pixelPos = ReconstructPosition(texcoords, u_depthBuffer, u_invViewProj);
    float dist = distance(u_viewPos, pixelPos);
    float minDist = u_minMaxDistance.x;
    float maxDist = u_minMaxDistance.y;

    float fog = clamp((dist - minDist) / (maxDist - minDist), 0, 1);
    vec3 pixel = mix(texture(tex, texcoords).rgb, u_fogColor, fog);

    return vec4(pixel, 1.0);
}