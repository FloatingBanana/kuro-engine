float SH9Evaluate(float[9] shCoeffs, vec3 dir) {
    return shCoeffs[0] * 0.282095
         + shCoeffs[1] * 0.488603 * dir.y
         + shCoeffs[2] * 0.488603 * dir.z
         + shCoeffs[3] * 0.488603 * dir.x
         + shCoeffs[4] * 1.092548 * dir.x * dir.y
         + shCoeffs[5] * 1.092548 * dir.y * dir.z
         + shCoeffs[6] * 0.315392 * (3.0 * dir.z * dir.z - 1.0)
         + shCoeffs[7] * 1.092548 * dir.x * dir.z
         + shCoeffs[8] * 0.546274 * (dir.x * dir.x - dir.y * dir.y);
}


vec3 SH9Evaluate(vec3[9] shCoeffs, vec3 dir) {
    return shCoeffs[0] * 0.282095
         + shCoeffs[1] * 0.488603 * dir.y
         + shCoeffs[2] * 0.488603 * dir.z
         + shCoeffs[3] * 0.488603 * dir.x
         + shCoeffs[4] * 1.092548 * dir.x * dir.y
         + shCoeffs[5] * 1.092548 * dir.y * dir.z
         + shCoeffs[6] * 0.315392 * (3.0 * dir.z * dir.z - 1.0)
         + shCoeffs[7] * 1.092548 * dir.x * dir.z
         + shCoeffs[8] * 0.546274 * (dir.x * dir.x - dir.y * dir.y);
}


float SH4Evaluate(float[4] shCoeffs, vec3 dir) {
    return shCoeffs[0] * 0.282095;
         + shCoeffs[1] * 0.488603 * dir.y;
         + shCoeffs[2] * 0.488603 * dir.z;
         + shCoeffs[3] * 0.488603 * dir.x;
}


vec3 SH4Evaluate(vec3[4] shCoeffs, vec3 dir) {
    return shCoeffs[0] * 0.282095;
         + shCoeffs[1] * 0.488603 * dir.y;
         + shCoeffs[2] * 0.488603 * dir.z;
         + shCoeffs[3] * 0.488603 * dir.x;
}