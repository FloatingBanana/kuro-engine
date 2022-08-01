varying highp vec3 v_VertexNormal;
varying highp vec3 v_FragPos;

#ifdef VERTEX
uniform mat4 u_world;
uniform mat4 u_invTranspWorld;
uniform mat4 u_view;
uniform mat4 u_proj;

attribute vec3 VertexNormal;

vec4 position(mat4 transformProjection, vec4 position) {
    v_VertexNormal = mat3(u_invTranspWorld) * VertexNormal;

    vec4 worldPos = u_world * position;

    v_FragPos = vec3(worldPos);

    return u_proj * u_view * worldPos;
}
#endif

#ifdef PIXEL
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
    vec3 normal = normalize(v_VertexNormal);
    vec3 viewDir = normalize(u_viewPosition - v_FragPos);

    vec3 result = CalculateDirectionalLight(u_dirLight, normal, viewDir);

    return vec4(result, 1.0);
}
#endif