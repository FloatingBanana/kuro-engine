struct DirectionalLight {
    vec3 direction;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform vec3 u_ambientColor;
uniform vec3 u_diffuseColor;
uniform vec3 u_specularColor;
uniform vec3 u_viewPosition;
uniform DirectionalLight u_dirLight;

varying vec3 v_vertexNormal;
varying vec3 v_fragPos;

vec3 CalculateDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

    vec3 ambient  = light.ambient  * u_diffuseColor;
    vec3 diffuse  = light.diffuse  * diff * u_diffuseColor;
    vec3 specular = light.specular * spec * u_specularColor;

    return (ambient + diffuse + specular);
}

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 normal = normalize(v_vertexNormal);
    vec3 viewDir = normalize(u_viewPosition - v_fragPos);

    vec3 result = CalculateDirectionalLight(u_dirLight, normal, viewDir);

    return vec4(result, 1.0);
}