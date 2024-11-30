#pragma language glsl3
#pragma include "engine/shaders/include/incl_lights.glsl"

uniform LightData light;
uniform int u_lightType;
in vec3 v_normal;
in vec3 v_fragPos;

#define BIAS(dir) (max(1.0 - dot(dir, v_normal), 0.1) * 0.000005)

void effect() {
	if (u_lightType == LIGHT_TYPE_DIRECTIONAL)
        gl_FragDepth = gl_FragCoord.z + BIAS(light.direction);

	else if (u_lightType == LIGHT_TYPE_SPOT)
        gl_FragDepth = gl_FragCoord.z + BIAS(normalize(light.position - v_fragPos));

	else if (u_lightType == LIGHT_TYPE_POINT)
        gl_FragDepth = length(v_fragPos - light.position) / light.farPlane;
}