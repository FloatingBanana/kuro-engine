#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#pragma include "engine/shaders/incl_commonBuffers.glsl"

in vec2 v_texCoords;
in mat3 v_tbnMatrix;

out vec4 oNormal;
out vec4 oAlbedoSpecular;

uniform sampler2D u_diffuseTexture;
uniform sampler2D u_normalMap;
uniform float u_shininess;

void effect() {
    vec3 normal = normalize(v_tbnMatrix * (texture(u_normalMap, v_texCoords).rgb * 2.0 - 1.0));

    oNormal         = vec4(EncodeNormal(normal), 1.0, 1.0);
    oAlbedoSpecular = vec4(texture(u_diffuseTexture, v_texCoords).rgb, u_shininess / 255.0);
}