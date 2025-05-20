#pragma include "engine/shaders/include/incl_sphericalHarmonics.glsl"


struct IrradianceVolume {
    sampler2D probeBuffer;
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

    int mwidth = textureSize(volume.probeBuffer, 0).x / 3;
    ivec2 mapPos = ivec2(index % mwidth, index / mwidth) * 3;

    for (int bx=0; bx < 3; bx++) {
        for (int by=0; by < 3; by++) {
            probe.coefficients[by * 3 + bx] = texelFetch(volume.probeBuffer, mapPos + ivec2(bx, by), 0).rgb;
        }
    }

    return probe;
}


const ivec3 neighborOffsets[8] = ivec3[] (
    ivec3(0,0,0),
    ivec3(1,0,0),
    ivec3(0,1,0),
    ivec3(1,1,0),
    ivec3(0,0,1),
    ivec3(1,0,1),
    ivec3(0,1,1),
    ivec3(1,1,1)
);

vec3 IrrV_getIrradiance(IrradianceVolume volume, vec3 pos, vec3 normal) {
    vec3 localPos = (volume.invTransform * vec4(pos, 1.0)).xyz;
    localPos = (localPos + 0.5) * volume.gridSize;

    ivec3 n = ivec3(sign(fract(localPos) - 0.5));

    vec3 res;
    for (int i=0; i < 8; i++) {
        ivec3 cell = ivec3(localPos) + n * neighborOffsets[i];
        int index = IrrV_getIndex(volume, clamp(cell, ivec3(0,0,0), ivec3(volume.gridSize)-1));

        vec3 probeDir = cell - (localPos - 0.5);
        vec3 trilinear = vec3(1,1,1) - clamp(abs(probeDir), vec3(0,0,0), vec3(1,1,1));

        SH9Color probe = IrrV_getProbe(volume, index);
        res += trilinear.x * trilinear.y * trilinear.z * EvaluateSH(probe, normal);
    }

    return res;
}