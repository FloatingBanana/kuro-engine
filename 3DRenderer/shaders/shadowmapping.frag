#define MAX_DIRECTIONAL_LIGHTS 1
#define MAX_POINT_LIGHTS 5
#define MAX_SPOT_LIGHTS 5

uniform struct DirectionalLight {
    vec3 position;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    bool enabled;

    sampler2D shadowMap;
    int mapSize;
};

uniform struct PointLight {
    vec3 position;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;

    float farPlane;

    bool enabled;

    samplerCube shadowMap;
};

uniform struct SpotLight {
    vec3 position;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float cutOff;
    float outerCutOff;

    bool enabled;

    sampler2D shadowMap;
    int mapSize;
};

uniform DirectionalLight u_directionalLights[MAX_DIRECTIONAL_LIGHTS];
uniform PointLight u_pointLights[MAX_POINT_LIGHTS];
uniform SpotLight u_spotLights[MAX_SPOT_LIGHTS];

uniform vec3 u_ambientColor;
uniform vec3 u_diffuseColor;
uniform vec3 u_specularColor;
uniform float u_shininess;
uniform vec3 u_viewPosition;

varying vec3 v_vertexNormal;
varying vec3 v_fragPos;
varying vec4 v_lightFragPos;

float ShadowCalculation(vec4 lightFragPos, sampler2D shadowMap, int mapSize) {
    vec3 projCoords = (lightFragPos.xyz / lightFragPos.w) * 0.5 + 0.5;
    float currentDepth = projCoords.z;

    if (currentDepth > 1.0)
        return 0.0;
    
    float shadow = 0.0;
    vec2 texelSize = 1.0 / vec2(mapSize);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            float pcfDepth = Texel(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r;
            shadow += currentDepth > pcfDepth ? 1.0 : 0.0;
        }
    }

    return shadow / 9.0;
}



vec3 sampleOffsetDirections[20] = vec3[] (
   vec3( 1, 1, 1), vec3( 1,-1, 1), vec3(-1,-1, 1), vec3(-1, 1, 1), 
   vec3( 1, 1,-1), vec3( 1,-1,-1), vec3(-1,-1,-1), vec3(-1, 1,-1),
   vec3( 1, 1, 0), vec3( 1,-1, 0), vec3(-1,-1, 0), vec3(-1, 1, 0),
   vec3( 1, 0, 1), vec3(-1, 0, 1), vec3( 1, 0,-1), vec3(-1, 0,-1),
   vec3( 0, 1, 1), vec3( 0,-1, 1), vec3( 0,-1,-1), vec3( 0, 1,-1)
);   


float ShadowCalculation(samplerCube shadowMap, vec3 lightPos, float farPlane) {
    vec3 fragToLight = v_fragPos - lightPos;
    float currentDepth = length(fragToLight);

    float bias = 0.05;
    int samples = 20;
    float viewDist = length(u_viewPosition - v_fragPos);
    float diskRadius = (1.0 - (viewDist / farPlane)) / 25.0;
    float shadow = 0.0;

    for (int i=0; i < samples; i++) {
        float closestDepth = Texel(shadowMap, fragToLight + sampleOffsetDirections[i] * diskRadius).r * farPlane;

        if (currentDepth - bias > closestDepth)
            shadow += 1.0;
    }

    return shadow / float(samples);
}

vec3 CalculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir) {
    if (!light.enabled)
        return vec3(0);
    
    vec3 lightDir = normalize(light.position);

    // Diffuse
    float lightDot = dot(normal, lightDir);
    float diff = max(lightDot, 0.0);

    // Specular
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    vec3 ambient  = light.ambient  * u_diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * u_diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    float shadow = ShadowCalculation(v_lightFragPos, light.shadowMap, light.mapSize);
    return ambient + (1.0 - shadow) * (diffuse + specular);
}

vec3 CalculatePointLight(PointLight light, vec3 normal, vec3 viewDir) {
    if (!light.enabled)
        return vec3(0);
    
    vec3 lightDir = normalize(light.position - v_fragPos);

    // Diffuse
    float lightDot = dot(normal, lightDir);
    float diff = max(lightDot, 0.0);

    // Specular
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    float dist = length(light.position - v_fragPos);
    float attenuation = 1.0 / (light.constant  + light.linear * dist + light.quadratic * (dist * dist));

    vec3 ambient  = light.ambient  * u_diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * u_diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    float shadow = ShadowCalculation(light.shadowMap, light.position, light.farPlane);
    return (ambient + (1.0 - shadow) * (diffuse + specular)) * attenuation;
}

vec3 CalculateSpotLight(SpotLight light, vec3 normal, vec3 viewDir) {
    if (!light.enabled)
        return vec3(0);
    
    vec3 lightDir = normalize(light.position - v_fragPos);

    vec3 color = light.ambient * u_diffuseColor;
    float theta = dot(lightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

        // Diffuse
        float lightDot = dot(normal, lightDir);
        float diffuse = max(lightDot, 0.0);

        // Specular
        vec3 halfwayDir = normalize(lightDir + viewDir);
        float specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);
        
        float shadow = ShadowCalculation(v_lightFragPos, light.shadowMap, light.mapSize);

        color += light.diffuse  * diffuse  * u_diffuseColor  * intensity * (1.0 - shadow);
        color += light.specular * specular * u_specularColor * intensity * (1.0 - shadow);
    }
    
    return color;
}

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 normal = normalize(v_vertexNormal);
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);

    vec3 result = CalculateDirectionalLight(u_directionalLights[0], normal, viewDir);

    result += CalculatePointLight(u_pointLights[0], normal, viewDir);
    result += CalculatePointLight(u_pointLights[1], normal, viewDir);
    result += CalculatePointLight(u_pointLights[2], normal, viewDir);
    result += CalculatePointLight(u_pointLights[3], normal, viewDir);
    result += CalculatePointLight(u_pointLights[4], normal, viewDir);
    
    result += CalculateSpotLight(u_spotLights[0], normal, viewDir);
    result += CalculateSpotLight(u_spotLights[1], normal, viewDir);
    result += CalculateSpotLight(u_spotLights[2], normal, viewDir);
    result += CalculateSpotLight(u_spotLights[3], normal, viewDir);
    result += CalculateSpotLight(u_spotLights[4], normal, viewDir);

    return vec4(result, 1.0);
}