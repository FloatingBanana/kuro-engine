#define MAX_DIRECTIONAL_LIGHTS 4
#define MAX_POINT_LIGHTS 10
#define MAX_SPOT_LIGHTS 10

struct DirectionalLight {
    vec3 direction;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3 position;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
};

struct SpotLight {
    vec3 position;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float cutOff;
    float outerCutOff;
};

uniform DirectionalLight u_directionalLights[MAX_DIRECTIONAL_LIGHTS];
uniform PointLight u_pointLights[MAX_POINT_LIGHTS];
uniform SpotLight u_spotLights[MAX_SPOT_LIGHTS];
uniform float u_directionalLightsCount;
uniform float u_pointLightsCount;
uniform float u_spotLightsCount;

uniform vec3 u_ambientColor;
uniform vec3 u_diffuseColor;
uniform vec3 u_specularColor;
uniform float u_shininess;
uniform vec3 u_viewPosition;

varying vec3 v_vertexNormal;
varying vec3 v_fragPos;

vec3 CalculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    vec3 ambient  = light.ambient  * u_diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * u_diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    return ambient + diffuse + specular;
}

vec3 CalculatePointLight(PointLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - v_fragPos);

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    float dist = length(light.position - v_fragPos);
    float attenuation = 1.0 / (light.constant  + light.linear * dist + light.quadratic * (dist * dist));

    vec3 ambient  = light.ambient  * u_diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * u_diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    return (ambient + diffuse + specular) * attenuation;
}

vec3 CalculateSpotLight(SpotLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - v_fragPos);

    vec3 color = light.ambient * u_diffuseColor;
    float theta = dot(lightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

        // Diffuse
        float diffuse = max(dot(normal, lightDir), 0.0);

        // Specular
        vec3 halfwayDir = normalize(lightDir + viewDir);
        float specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);
        
        color += light.diffuse  * diffuse  * u_diffuseColor  * intensity;
        color += light.specular * specular * u_specularColor * intensity;
    }
    
    return color;
}

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 normal = normalize(v_vertexNormal);
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);

    vec3 result = vec3(0,0,0);

    for (int i=0; i < u_directionalLightsCount; i++) {
        result += CalculateDirectionalLight(u_directionalLights[i], normal, viewDir);
    }

    for (int i=0; i < u_pointLightsCount; i++) {
        result += CalculatePointLight(u_pointLights[i], normal, viewDir);
    }

    for (int i=0; i < u_spotLightsCount; i++) {
        result += CalculateSpotLight(u_spotLights[i], normal, viewDir);
    }

    return vec4(result, 1.0);
}