const vec3 sampleOffsetDirections[20] = vec3[] (
   vec3( 1, 1, 1), vec3( 1,-1, 1), vec3(-1,-1, 1), vec3(-1, 1, 1), 
   vec3( 1, 1,-1), vec3( 1,-1,-1), vec3(-1,-1,-1), vec3(-1, 1,-1),
   vec3( 1, 1, 0), vec3( 1,-1, 0), vec3(-1,-1, 0), vec3(-1, 1, 0),
   vec3( 1, 0, 1), vec3(-1, 0, 1), vec3( 1, 0,-1), vec3(-1, 0,-1),
   vec3( 0, 1, 1), vec3( 0,-1, 1), vec3( 0,-1,-1), vec3( 0, 1,-1)
);

// Point light
float ShadowCalculation(vec3 position, float farPlane, samplerCube shadowMap, vec3 viewPos, vec3 fragPos) {
    vec3 fragToLight = fragPos - position;
    float currentDepth = length(fragToLight);

    float bias = 0.05;
    int samples = 20;
    float viewDist = length(viewPos - fragPos);
    float diskRadius = (1.0 - (viewDist / farPlane)) / 25.0;
    float shadow = 0.0;

    for (int i=0; i < samples; i++) {
        float closestDepth = texture(shadowMap, fragToLight + sampleOffsetDirections[i] * diskRadius).r * farPlane;
        shadow += step(closestDepth, currentDepth - bias);

        // if (currentDepth - bias > closestDepth)
        //     shadow += 1.0;
    }

    return shadow / float(samples);
}

// Directional and spot lights
float ShadowCalculation(sampler2D shadowMap, vec4 lightFragPos) {
    vec3 projCoords = (lightFragPos.xyz / lightFragPos.w) * 0.5 + 0.5;
    float currentDepth = projCoords.z;

    if (currentDepth > 1.0)
        return 0.0;
    
    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            float pcfDepth = Texel(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r;
            shadow += step(pcfDepth, currentDepth);
            // shadow += currentDepth > pcfDepth ? 1.0 : 0.0;
        }
    }

    return shadow / 9.0;
}