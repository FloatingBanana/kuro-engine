#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"

uniform vec2 u_minMaxDistance;
uniform vec3 u_fogColor;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 pixelPos = ReconstructPosition(texcoords, uDepthBuffer, uInvViewProjMatrix);
    float dist = distance(uViewPosition, pixelPos);
    float minDist = u_minMaxDistance.x;
    float maxDist = u_minMaxDistance.y;

    float fog = clamp((dist - minDist) / (maxDist - minDist), 0, 1);
    vec3 pixel = mix(texture(tex, texcoords).rgb, u_fogColor, fog);

    return vec4(pixel, 1.0);
}