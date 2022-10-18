#define MAX_DIRECTIONAL_LIGHTS 1
#define MAX_POINT_LIGHTS 5
#define MAX_SPOT_LIGHTS 5

struct DirectionalLight {
    vec3 direction;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    bool enabled;

    sampler2D shadowMap;
    int mapSize;
    mat4 lightMatrix;
};

struct PointLight {
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

struct SpotLight {
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
    mat4 lightMatrix;
};

varying vec3 v_normal;
varying vec2 v_texCoords;
varying vec3 v_fragPos;

uniform DirectionalLight u_directionalLights[MAX_DIRECTIONAL_LIGHTS];
uniform PointLight u_pointLights[MAX_POINT_LIGHTS];
uniform SpotLight u_spotLights[MAX_SPOT_LIGHTS];

uniform vec3 u_specularColor;
uniform float u_shininess;
uniform vec3 u_viewPosition;
uniform sampler2D u_diffuseTexture;

const vec3 sampleOffsetDirections[20] = vec3[] (
   vec3( 1, 1, 1), vec3( 1,-1, 1), vec3(-1,-1, 1), vec3(-1, 1, 1), 
   vec3( 1, 1,-1), vec3( 1,-1,-1), vec3(-1,-1,-1), vec3(-1, 1,-1),
   vec3( 1, 1, 0), vec3( 1,-1, 0), vec3(-1,-1, 0), vec3(-1, 1, 0),
   vec3( 1, 0, 1), vec3(-1, 0, 1), vec3( 1, 0,-1), vec3(-1, 0,-1),
   vec3( 0, 1, 1), vec3( 0,-1, 1), vec3( 0,-1,-1), vec3( 0, 1,-1)
);

////////////////////////
// Shadow calculation //
////////////////////////
// Point light
float ShadowCalculation(PointLight light) {
    vec3 fragToLight = v_fragPos - light.position;
    float currentDepth = length(fragToLight);

    float bias = 0.05;
    int samples = 20;
    float viewDist = length(u_viewPosition - v_fragPos);
    float diskRadius = (1.0 - (viewDist / light.farPlane)) / 25.0;
    float shadow = 0.0;

    for (int i=0; i < samples; i++) {
        float closestDepth = textureCube(light.shadowMap, fragToLight + sampleOffsetDirections[i] * diskRadius).r * light.farPlane;

        if (currentDepth - bias > closestDepth)
            shadow += 1.0;
    }

    return shadow / float(samples);
}

// Directional and spot lights
float ShadowCalculation(mat4 lightMatrix, sampler2D shadowMap, int mapSize) {
    // TODO: avoid doing this operation on fragment shader
    vec4 lightFragPos = lightMatrix * vec4(v_fragPos, 1.0);
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


///////////////////////
// Light calculation //
///////////////////////
vec3 CalculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir, vec3 diffuseColor) {
    if (!light.enabled)
        return vec3(0);

    // Diffuse
    float diff = max(dot(normal, light.direction), 0.0);

    // Specular
    vec3 halfwayDir = normalize(light.direction + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    vec3 ambient  = light.ambient  * diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    float shadow = ShadowCalculation(light.lightMatrix, light.shadowMap, light.mapSize);
    return ambient + (1.0 - shadow) * (diffuse + specular);
}

vec3 CalculateSpotLight(SpotLight light, vec3 normal, vec3 viewDir, vec3 diffuseColor) {
    if (!light.enabled)
        return vec3(0);

    vec3 lightDir = normalize(light.position - v_fragPos);

    vec3 color = light.ambient * diffuseColor;
    float theta = dot(lightDir, -light.direction);

    if (theta > light.outerCutOff) {
        float epsilon = light.cutOff - light.outerCutOff;
        float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

        // Diffuse
        float diffuse = max(dot(normal, lightDir), 0.0);

        // Specular
        vec3 halfwayDir = normalize(lightDir + viewDir);
        float specular = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);
        
        float shadow = ShadowCalculation(light.lightMatrix, light.shadowMap, light.mapSize);
        float visibility = (1.0 - shadow) * intensity;

        color += light.diffuse  * diffuse  * diffuseColor * visibility;
        color += light.specular * specular * u_specularColor * visibility;
    }
    
    return color;
}

vec3 CalculatePointLight(PointLight light, vec3 normal, vec3 viewDir, vec3 diffuseColor) {
    if (!light.enabled)
        return vec3(0);
    
    vec3 lightDir = normalize(light.position - v_fragPos);

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), u_shininess);

    float dist = length(light.position - v_fragPos);
    float attenuation = 1.0 / (light.constant  + light.linear * dist + light.quadratic * (dist * dist));

    vec3 ambient  = light.ambient  * diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    float visibility = 1.0 - ShadowCalculation(light);

    return (ambient + (diffuse + specular) * visibility) * attenuation;
}


///////////////////
// Main function //
///////////////////
void effect() {
    vec3 normal = normalize(v_normal);
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);

    vec3 diffuseColor = Texel(u_diffuseTexture, v_texCoords).xyz;

    vec3 result = CalculateDirectionalLight(u_directionalLights[0], normal, viewDir, diffuseColor);

    result += CalculatePointLight(u_pointLights[0], normal, viewDir, diffuseColor);
    result += CalculatePointLight(u_pointLights[1], normal, viewDir, diffuseColor);
    result += CalculatePointLight(u_pointLights[2], normal, viewDir, diffuseColor);
    result += CalculatePointLight(u_pointLights[3], normal, viewDir, diffuseColor);
    result += CalculatePointLight(u_pointLights[4], normal, viewDir, diffuseColor);
    
    result += CalculateSpotLight(u_spotLights[0], normal, viewDir, diffuseColor);
    result += CalculateSpotLight(u_spotLights[1], normal, viewDir, diffuseColor);
    result += CalculateSpotLight(u_spotLights[2], normal, viewDir, diffuseColor);
    result += CalculateSpotLight(u_spotLights[3], normal, viewDir, diffuseColor);
    result += CalculateSpotLight(u_spotLights[4], normal, viewDir, diffuseColor);

    gl_FragColor = vec4(result, 1.0);
}