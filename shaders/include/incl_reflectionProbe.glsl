#define MAX_REFLECTION_LOD 4.0

struct ReflectionProbeAABB {
    samplerCube texture;
    vec3 min;
    vec3 max;
};

struct ReflectionProbeOBB {
    samplerCube texture;
    mat4 invTransform;
    vec3 position;
};

vec3 CalculateReflectionProbeColor(ReflectionProbeAABB probe, vec3 viewPos, vec3 fragPos, vec3 normal, float roughness) {
    vec3 viewDir = fragPos - viewPos;
    vec3 reflectDir = reflect(viewDir, normal);

    vec3 point1 = (probe.max - fragPos) / reflectDir;
    vec3 point2 = (probe.min - fragPos) / reflectDir;

    vec3 furthestPoint = max(point1, point2);
    float dist = min(min(furthestPoint.x, furthestPoint.y), furthestPoint.z);

    vec3 worldIntersectPoint = fragPos + reflectDir * dist;
    reflectDir = worldIntersectPoint - (probe.min + probe.max) * 0.5;

    return textureLod(probe.texture, reflectDir, roughness * MAX_REFLECTION_LOD).rgb;
}

vec3 CalculateReflectionProbeColor(ReflectionProbeOBB probe, vec3 viewPos, vec3 fragPos, vec3 normal, float roughness) {
    vec3 viewDir = normalize(fragPos - viewPos);
    vec3 reflectDir = reflect(viewDir, normal);

    vec3 localPos = (probe.invTransform * vec4(fragPos, 1.0)).xyz;
    vec3 localRay = mat3(probe.invTransform) * reflectDir;

    const vec3 halfSize = vec3(0.5);
    vec3 point1 = (-halfSize - localPos) / localRay;
    vec3 point2 = ( halfSize - localPos) / localRay;
    
    vec3 furthestPoint = max(point1, point2);
    float dist = min(min(furthestPoint.x, furthestPoint.y), furthestPoint.z);

    vec3 worldIntersectPoint = fragPos + reflectDir * dist;
    reflectDir = worldIntersectPoint - probe.position;

    return textureLod(probe.texture, reflectDir, roughness * MAX_REFLECTION_LOD).rgb;
}