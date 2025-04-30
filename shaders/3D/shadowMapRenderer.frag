#pragma language glsl3
#pragma include "engine/shaders/include/incl_lights.glsl"

uniform LightData light;
uniform int u_lightType;
in vec3 v_fragPos;


void effect() {
	if (u_lightType == LIGHT_TYPE_POINT) {
		vec3 fragToLight = v_fragPos - light.position;
		gl_FragDepth = length(fragToLight) / light.farPlane;
	}
	else
		gl_FragDepth = gl_FragCoord.z;
}