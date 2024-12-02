#pragma include "engine/shaders/include/incl_dualQuaternion.glsl"

mat4 GetLinearBlendingSkinningMatrix(mat4 boneMatrices[MAX_BONE_COUNT], vec4 boneIDs, vec4 weights) {
    mat4 boneTransform = mat4(0);
    bool hasBones = false;

    for (int i=0; i < 4; i++) {
        if (boneIDs[i] < 0)
            continue;
        if (boneIDs[i] >= MAX_BONE_COUNT) {
            hasBones = false;
            break;
        }

        boneTransform += boneMatrices[int(boneIDs[i])] * weights[i];
        hasBones = true;
    }

    if (hasBones)
        return boneTransform;

    return mat4(1.0);
}


vec3 GetScalingSkinning(vec3 boneScales[MAX_BONE_COUNT], vec4 boneIDs, vec4 weights) {
    vec3 boneScale = vec3(0);
    bool hasBones = false;

    for (int i=0; i < 4; i++) {
        if (boneIDs[i] < 0)
            continue;
        if (boneIDs[i] >= MAX_BONE_COUNT) {
            hasBones = false;
            break;
        }

        boneScale += boneScales[int(boneIDs[i])] * weights[i];
        hasBones = true;
    }

    if (hasBones)
        return boneScale;

    return vec3(1.0);
}


DualQuaternion GetDualQuaternionSkinning(vec4 boneQuaternions[MAX_BONE_COUNT*2], vec4 boneIDs, vec4 weights) {
    bool hasBones = false;
	DualQuaternion dqBlend = DualQuaternion(vec4(0), vec4(0));

    for (int i=0; i < 4; i++) {
        if (boneIDs[i] < 0)
            continue;
        if (boneIDs[i] >= MAX_BONE_COUNT) {
            hasBones = false;
            break;
        }
        int id = int(boneIDs[i]);
		DualQuaternion dq = DualQuaternion(boneQuaternions[id*2], boneQuaternions[id*2+1]);

		dqBlend = dq_add(dqBlend, dq_multiply(dq, weights[i]));
        hasBones = true;
    }

    if (hasBones) {
		return dq_normalize(dqBlend);
	}

    return dq_identity();
}