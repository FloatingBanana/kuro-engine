#pragma language glsl3

#define MAX_LIGHTS 10
#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1
#define LIGHT_TYPE_POINT 2

varying vec2 v_texCoords;
varying vec3 v_fragPos;
varying mat3 v_tbnMatrix;
varying vec4 v_lightSpaceFragPos[MAX_LIGHTS];

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

uniform vec3 u_viewPosition;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;


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
vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess, float ambientOcclusion);
vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, sampler2D shadowMap, vec3 matDiffuseColor, float matShininess, float ambientOcclusion, vec3 fragPos);
vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 viewPos, samplerCube shadowMap, vec3 matDiffuseColor, float matShininess, float ambientOcclusion, vec3 fragPos);
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"


///////////////////
// Main function //
///////////////////
void effect() {
    vec3 normal = normalize(v_tbnMatrix * (Texel(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);
    vec3 diffuseColor = Texel(u_diffuseTexture, v_texCoords).xyz;

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
            light.fragPos = v_lightSpaceFragPos[INDEX];


            if (u_lightType[INDEX] == LIGHT_TYPE_DIRECTIONAL)
                result += CalculateDirectionalLight(light, normal, viewDir, u_lightShadowMap[INDEX], diffuseColor, u_shininess, 1);

            if (u_lightType[INDEX] == LIGHT_TYPE_SPOT)
                result += CalculateSpotLight(light, normal, viewDir, u_lightShadowMap[INDEX], diffuseColor, u_shininess, 1, v_fragPos);

            if (u_lightType[INDEX] == LIGHT_TYPE_POINT)
                result += CalculatePointLight(light, normal, viewDir, u_viewPosition, u_pointLightShadowMap[INDEX], diffuseColor, u_shininess, 1, v_fragPos);
        }
#   pragma endfor

    gl_FragColor = vec4(result, 1.0);
}