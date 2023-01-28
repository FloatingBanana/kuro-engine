#define MAX_LIGHTS 10

#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_SPOT 1
#define LIGHT_TYPE_POINT 2

struct PhongColor {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

varying vec2 v_texCoords;
varying vec3 v_fragPos;
varying mat3 v_tbnMatrix;
varying vec4 v_lightSpaceFragPos[MAX_LIGHTS];

uniform vec3 u_lightPosition[MAX_LIGHTS];
uniform vec3 u_lightDirection[MAX_LIGHTS];
uniform int u_lightType[MAX_LIGHTS];
uniform PhongColor u_lightColor[MAX_LIGHTS];
uniform vec4 u_lightVars[MAX_LIGHTS];
uniform int u_lightMapSize[MAX_LIGHTS];
uniform bool u_lightEnabled[MAX_LIGHTS];
uniform sampler2D u_lightShadowMap[MAX_LIGHTS];
uniform samplerCube u_pointLightShadowMap[MAX_LIGHTS];

uniform vec3 u_viewPosition;
uniform vec3 u_specularColor;
uniform float u_shininess;
uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;


float ShadowCalculation(vec3 position, float farPlane, samplerCube shadowMap, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(sampler2D shadowMap, int mapSize, vec4 lightFragPos);
#pragma include "engine/shaders/3D/forwardRendering/_shadowCalculation.glsl"


///////////////////////
// Light calculation //
///////////////////////
vec3 CalculateDirectionalLight(int index, vec3 normal, vec3 viewDir, sampler2D shadowMap, PhongColor matColor) {
    PhongColor lightColor = u_lightColor[index];
    vec3 lightDir = u_lightDirection[index];
    vec4 lightFragPos = v_lightSpaceFragPos[index];
    int mapSize = u_lightMapSize[index];

    vec3 ambient = lightColor.ambient  * matColor.diffuse;
    vec3 diffuse = max(dot(normal, lightDir), 0.0) * lightColor.diffuse * matColor.diffuse;

    vec3 halfwayDir = normalize(lightDir + viewDir);
    vec3 specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess) * lightColor.diffuse * matColor.diffuse;


    float shadow = ShadowCalculation(shadowMap, mapSize, lightFragPos);
    return ambient + (1.0 - shadow) * (diffuse + specular);
}

vec3 CalculateSpotLight(int index, vec3 normal, vec3 viewDir, sampler2D shadowMap, PhongColor matColor) {
    PhongColor lightColor = u_lightColor[index];
    vec3 lightPos = u_lightPosition[index];
    vec3 spotDir = u_lightDirection[index];
    vec4 lightFragPos = v_lightSpaceFragPos[index];
    int mapSize = u_lightMapSize[index];
    float cutOff = u_lightVars[index].x;
    float outerCutOff = u_lightVars[index].y;
    
    vec3 lightDir = normalize(lightPos - v_fragPos);
    float theta = dot(lightDir, -spotDir);
    vec3 color = lightColor.ambient * matColor.diffuse;

    if (theta > outerCutOff) {
        float epsilon = cutOff - outerCutOff;
        float intensity = clamp((theta - outerCutOff) / epsilon, 0.0, 1.0);

        float diffuse = max(dot(normal, lightDir), 0.0);

        vec3 halfwayDir = normalize(lightDir + viewDir);
        float specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);
        
        float shadow = ShadowCalculation(shadowMap, mapSize, lightFragPos);
        float visibility = (1.0 - shadow) * intensity;

        color += lightColor.diffuse  * diffuse  * matColor.diffuse  * visibility;
        color += lightColor.specular * specular * matColor.specular * visibility;
    }
    
    return color;
}

vec3 CalculatePointLight(int index, vec3 normal, vec3 viewDir, samplerCube shadowMap, PhongColor matColor) {
    PhongColor lightColor = u_lightColor[index];
    vec3 lightPos = u_lightPosition[index];
    int mapSize = u_lightMapSize[index];
    float linear = u_lightVars[index].x;
    float constant = u_lightVars[index].y;
    float quadratic = u_lightVars[index].z;
    float farPlane = u_lightVars[index].w;
    
    vec3 lightDir = normalize(lightPos - v_fragPos);
    vec3 diffuse = max(dot(normal, lightDir), 0.0) * lightColor.diffuse * matColor.diffuse;

    vec3 halfwayDir = normalize(lightDir + viewDir);
    vec3 specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess) * lightColor.specular * matColor.specular;

    float dist = length(lightPos - v_fragPos);
    float attenuation = 1.0 / (constant  + linear * dist + quadratic * (dist * dist));

    float visibility = 1.0 - ShadowCalculation(u_lightPosition[index], farPlane, shadowMap, u_viewPosition, v_fragPos);
    vec3 ambient = lightColor.ambient * matColor.diffuse;

    return (ambient + (diffuse + specular) * visibility) * attenuation;
}


///////////////////
// Main function //
///////////////////
void effect() {
    vec3 normal = normalize(v_tbnMatrix * (Texel(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);
    vec3 diffuseColor = Texel(u_diffuseTexture, v_texCoords).xyz;

    vec3 result;
    PhongColor matColor;
    matColor.diffuse = diffuseColor;
    matColor.specular = u_specularColor;

#   define INDEX 0
#   pragma for INDEX=0, MAX_LIGHTS, 1
        if (u_lightEnabled[INDEX]) {
            if (u_lightType[INDEX] == LIGHT_TYPE_DIRECTIONAL)
                result += CalculateDirectionalLight(INDEX, normal, viewDir, u_lightShadowMap[INDEX], matColor);

            if (u_lightType[INDEX] == LIGHT_TYPE_SPOT)
                result += CalculateSpotLight(INDEX, normal, viewDir, u_lightShadowMap[INDEX], matColor);

            if (u_lightType[INDEX] == LIGHT_TYPE_POINT)
                result += CalculatePointLight(INDEX, normal, viewDir, u_pointLightShadowMap[INDEX], matColor);
    }
#   pragma endfor

    gl_FragColor = vec4(result, 1.0);
}