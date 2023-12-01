#pragma language glsl3

#ifdef VERTEX
uniform mat4 u_volumeTransform;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 screenPos = u_volumeTransform * position;
    screenPos.y *= -1.0;

    return screenPos;
}
#endif

#ifdef PIXEL

#define PHONG_LIGHT_STRUCT_DECLARED
struct PhongLight {
    vec3 position;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    // spot light
    float cutOff;
    float outerCutOff;

    // point light
    float constant;
    float linear;
    float quadratic;
    float farPlane;

    // mat4 lightSpaceMatrix;
    vec4 fragPos;
};
vec3 CalculateAmbientLight(PhongLight light, vec3 matDiffuseColor);
vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess);
vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"

float ShadowCalculation(vec3 position, float farPlane, samplerCube shadowMap, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(sampler2D shadowMap, vec4 lightFragPos);
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"

uniform PhongLight light;
uniform vec3 u_viewPosition;
uniform sampler2D u_gPosition;
uniform sampler2D u_gNormal;
uniform sampler2D u_gAlbedoSpec;
uniform sampler2D u_ssaoTex;
uniform sampler2D u_lightShadowMap;
uniform samplerCube u_pointLightShadowMap;
uniform mat4 u_lightMatrix;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
	vec2 uv = screencoords / textureSize(u_gPosition, 0); // Handle various volume shapes
	
    vec3 fragPos = texture2D(u_gPosition, uv).rgb;
    vec3 normal = texture2D(u_gNormal, uv).rgb;
    vec3 albedo = texture2D(u_gAlbedoSpec, uv).rgb;
    float specular = texture2D(u_gAlbedoSpec, uv).a * 32.0; // hackish way to get the specular value, gonna fix later

    vec4 lightSpaceFragPos = u_lightMatrix * vec4(fragPos, 1.0);
    vec3 viewDir = normalize(u_viewPosition - fragPos);
    vec3 result = vec3(0);
    float shadow = 0;

#   ifdef LIGHT_TYPE_DIRECTIONAL
        result = CalculateDirectionalLight(light, normal, viewDir, albedo, specular);
        shadow = ShadowCalculation(u_lightShadowMap, lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_SPOT
        result = CalculateSpotLight(light, normal, viewDir, albedo, specular, fragPos);
        shadow = ShadowCalculation(u_lightShadowMap, lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_POINT
        result = CalculatePointLight(light, normal, viewDir, albedo, specular, fragPos);
        shadow = ShadowCalculation(light.position, light.farPlane, u_pointLightShadowMap, u_viewPosition, fragPos);
#   endif

#   ifdef LIGHT_TYPE_AMBIENT
        result = CalculateAmbientLight(light, albedo);
        shadow = 1.0 - texture2D(u_ssaoTex, uv).r;
#   endif

    return vec4(result * (1.0 - shadow), 1.0);
}

#endif