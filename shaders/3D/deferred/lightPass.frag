#pragma language glsl3

#define MAX_LIGHTS 10
#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1
#define LIGHT_TYPE_POINT 2

uniform vec3 u_lightPosition[MAX_LIGHTS];
uniform vec3 u_lightDirection[MAX_LIGHTS];
uniform int u_lightType[MAX_LIGHTS];
uniform vec3 u_lightAmbient[MAX_LIGHTS];
uniform vec3 u_lightDiffuse[MAX_LIGHTS];
uniform vec3 u_lightSpecular[MAX_LIGHTS];
uniform vec4 u_lightVars[MAX_LIGHTS];
uniform bool u_lightEnabled[MAX_LIGHTS];
uniform sampler2D u_lightShadowMap[MAX_LIGHTS];
uniform samplerCube u_pointLightShadowMap[MAX_LIGHTS];
uniform mat4 u_lightMatrix[MAX_LIGHTS];

uniform vec3 u_viewPosition;
uniform sampler2D u_gPosition;
uniform sampler2D u_gNormal;
uniform sampler2D u_gAlbedoSpec;

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

    vec4 fragPos;
};
vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess);
vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 viewPos, samplerCube shadowMap, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 fragPos = texture2D(u_gPosition, texcoords).rgb;
    vec3 normal = texture2D(u_gNormal, texcoords).rgb;
    vec3 albedo = texture2D(u_gAlbedoSpec, texcoords).rgb;
    float specular = texture2D(u_gAlbedoSpec, texcoords).a * 32.0; // hackish way to get the specular value, gonna fix later

    vec3 viewDir = normalize(u_viewPosition - fragPos);
    vec3 result;
    PhongLight light;

#   define INDEX 0
#   pragma for INDEX=0, MAX_LIGHTS, 1
        if (u_lightEnabled[INDEX]) {
            light.position = u_lightPosition[INDEX];
            light.direction = u_lightDirection[INDEX];
            light.ambient = u_lightAmbient[INDEX];
            light.diffuse = u_lightDiffuse[INDEX];
            light.specular = u_lightSpecular[INDEX];
            light.cutOff = u_lightVars[INDEX].x;
            light.outerCutOff = u_lightVars[INDEX].y;
            light.constant = u_lightVars[INDEX].x;
            light.linear = u_lightVars[INDEX].y;
            light.quadratic = u_lightVars[INDEX].z;
            light.farPlane = u_lightVars[INDEX].w;
            light.fragPos = u_lightMatrix[INDEX] * vec4(fragPos, 1.0);


            if (u_lightType[INDEX] == LIGHT_TYPE_DIRECTIONAL)
                result += CalculateDirectionalLight(light, normal, viewDir, u_lightShadowMap[INDEX], albedo, specular);

            if (u_lightType[INDEX] == LIGHT_TYPE_SPOT)
                result += CalculateSpotLight(light, normal, viewDir, u_lightShadowMap[INDEX], albedo, specular, fragPos);

            if (u_lightType[INDEX] == LIGHT_TYPE_POINT)
                result += CalculatePointLight(light, normal, viewDir, u_viewPosition, u_pointLightShadowMap[INDEX], albedo, specular, fragPos);
        }
#   pragma endfor

    return vec4(result, 1.0);
}