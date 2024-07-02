#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_lights.glsl"

uniform LightData light;
in vec3 v_normal;
in vec3 v_fragPos;

#define BIAS(dir) (max(1.0 - dot(dir, v_normal), 0.1) * 0.000005)

void effect() {
#   if CURRENT_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
        gl_FragDepth = gl_FragCoord.z + BIAS(light.direction);

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_SPOT
        gl_FragDepth = gl_FragCoord.z + BIAS(normalize(light.position - v_fragPos));

#   elif CURRENT_LIGHT_TYPE == LIGHT_TYPE_POINT
        gl_FragDepth = length(v_fragPos - light.position) / light.farPlane;
#   endif
}