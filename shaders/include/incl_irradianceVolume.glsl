#pragma include "engine/shaders/include/incl_sphericalHarmonics.glsl"


struct IrradianceVolume {
    sampler2D probeBuffer;
    mat4 transform;
    mat4 invTransform;
    vec3 gridSize;
};


ivec3 IrrV_getCell(IrradianceVolume volume, int index) {
    ivec3 size = ivec3(volume.gridSize);
    int z = index / (size.x * size.y);
    index = index - (z * size.x * size.y);
    int y = index / size.x;
    int x = index % size.x;
    
    return ivec3(x, y, z);
}

int IrrV_getIndex(IrradianceVolume volume, ivec3 cell) {
    ivec3 size = ivec3(volume.gridSize);
    return (cell.z * size.x * size.y) + (cell.y * size.x) + cell.x;
}

SH9Color IrrV_getProbe(IrradianceVolume volume, int index) {
    SH9Color probe;

    for (int i=0; i < 9; i++) {
        probe.coefficients[i] = texelFetch(volume.probeBuffer, ivec2(index, i), 0).rgb;
    }

    return probe;
}

SH9Color IrrV_getProbe(IrradianceVolume volume, ivec3 cell) {
    return IrrV_getProbe(volume, IrrV_getIndex(volume, cell));
}

vec3 IrrV_getCellPosition(IrradianceVolume volume, ivec3 cell) {
    vec3 cellCenter = 1.0 / volume.gridSize * 0.5;
    vec3 probePos = (cell / volume.gridSize) + cellCenter - 0.5;

    return (volume.transform * vec4(probePos, 1.0)).xyz;
}


ivec3 IrrV_getNearestCell(IrradianceVolume volume, vec3 pos) {
    vec3 localPos = (volume.invTransform * vec4(pos, 1.0)).xyz;
    localPos = (localPos + 0.5) * volume.gridSize;

    return ivec3(localPos);
}

void IrrV_getNeighborCells(IrradianceVolume volume, vec3 pos, out ivec3 neighbors[8], out vec3 distances) {
    vec3 localPos = (volume.invTransform * vec4(pos, 1.0)).xyz;
    localPos = (localPos + 0.5) * volume.gridSize;

    vec3 signedDist = fract(localPos) - 0.5;
    ivec3 n = ivec3(sign(signedDist));
    ivec3 cell = ivec3(localPos);

    distances = abs(signedDist);
    neighbors = ivec3[] (
        cell,
        cell + n * ivec3(1,0,0),
        cell + n * ivec3(0,1,0),
        cell + n * ivec3(1,1,0),
        cell + n * ivec3(0,0,1),
        cell + n * ivec3(1,0,1),
        cell + n * ivec3(0,1,1),
        cell + n * ivec3(1,1,1)
    );
}

vec3 IrrV_getIrradiance(IrradianceVolume volume, vec3 pos, vec3 normal) {
    ivec3 neighbors[8];
    vec3 distances;
    IrrV_getNeighborCells(volume, pos, neighbors, distances);

    vec3 probeIrr[8];
    for (int i=0; i < 8; i++) {
        ivec3 cell = clamp(neighbors[i], ivec3(0,0,0), ivec3(volume.gridSize)-1);
        SH9Color probe = IrrV_getProbe(volume, cell);

        probeIrr[i] = EvaluateSH(probe, normal.xzy);
    }

    vec3 nearBottom = mix(probeIrr[0], probeIrr[1], distances.x);
    vec3 nearTop = mix(probeIrr[2], probeIrr[3], distances.x);
    vec3 near = mix(nearBottom, nearTop, distances.y);

    vec3 farBottom = mix(probeIrr[4], probeIrr[5], distances.x);
    vec3 farTop = mix(probeIrr[6], probeIrr[7], distances.x);
    vec3 far = mix(farBottom, farTop, distances.y);

    return mix(near, far, distances.z);
}