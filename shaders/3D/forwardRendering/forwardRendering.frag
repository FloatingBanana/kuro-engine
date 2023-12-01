#pragma language glsl3

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

    mat4 lightSpaceMatrix;
};
vec3 CalculateAmbientLight(PhongLight light, vec3 matDiffuseColor);
vec3 CalculateDirectionalLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess);
vec3 CalculateSpotLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
vec3 CalculatePointLight(PhongLight light, vec3 normal, vec3 viewDir, vec3 matDiffuseColor, float matShininess, vec3 fragPos);
#pragma include "engine/shaders/3D/misc/incl_phongLighting.glsl"

float ShadowCalculation(vec3 position, float farPlane, samplerCube shadowMap, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(sampler2D shadowMap, vec4 lightFragPos);
#pragma include "engine/shaders/3D/misc/incl_shadowCalculation.glsl"


in vec2 v_texCoords;
in vec3 v_fragPos;
in vec4 v_screenPos;
in mat3 v_tbnMatrix;
in vec4 v_lightSpaceFragPos;

out vec4 FragColor;

uniform PhongLight light;
uniform vec3 u_viewPosition;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform sampler2D u_ssaoTex;
uniform sampler2D u_lightShadowMap;
uniform samplerCube u_pointLightShadowMap;

///////////////////
// Main function //
///////////////////
void effect() {
    vec3 normal = normalize(v_tbnMatrix * (Texel(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);
    vec3 diffuseColor = Texel(u_diffuseTexture, v_texCoords).xyz;
    vec3 result = vec3(0);
    float shadow = 0;

#   ifdef LIGHT_TYPE_DIRECTIONAL
        result = CalculateDirectionalLight(light, normal, viewDir, diffuseColor, u_shininess);
        shadow = ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_SPOT
        result = CalculateSpotLight(light, normal, viewDir, diffuseColor, u_shininess, v_fragPos);
        shadow = ShadowCalculation(u_lightShadowMap, v_lightSpaceFragPos);
#   endif

#   ifdef LIGHT_TYPE_POINT
        result = CalculatePointLight(light, normal, viewDir, diffuseColor, u_shininess, v_fragPos);
        shadow = ShadowCalculation(light.position, light.farPlane, u_pointLightShadowMap, u_viewPosition, v_fragPos);
#   endif

#   ifdef LIGHT_TYPE_AMBIENT
        vec2 samplePos = (v_screenPos.xy / v_screenPos.w) * 0.5 + 0.5;

        result = CalculateAmbientLight(light, diffuseColor);
        shadow = 1.0 - texture2D(u_ssaoTex, samplePos).r;
#   endif

    FragColor = vec4(result * (1.0 - shadow), 1.0);
}