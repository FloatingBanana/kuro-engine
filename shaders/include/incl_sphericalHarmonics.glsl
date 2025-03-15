struct SH9 {
    float coefficients[9];
};

struct SH9Color {
    vec3 coefficients[9];
};

struct SH4 {
    float coefficients[4];
};

struct SH4Color {
    vec3 coefficients[4];
};


float EvaluateSH(SH9 sh, vec3 dir) {
    return sh.coefficients[0] * 0.282095
         + sh.coefficients[1] * 0.488603 * dir.y
         + sh.coefficients[2] * 0.488603 * dir.z
         + sh.coefficients[3] * 0.488603 * dir.x
         + sh.coefficients[4] * 1.092548 * dir.x * dir.y
         + sh.coefficients[5] * 1.092548 * dir.y * dir.z
         + sh.coefficients[6] * 0.315392 * (3.0 * dir.z * dir.z - 1.0)
         + sh.coefficients[7] * 1.092548 * dir.x * dir.z
         + sh.coefficients[8] * 0.546274 * (dir.x * dir.x - dir.y * dir.y);
}


vec3 EvaluateSH(SH9Color sh, vec3 dir) {
    return sh.coefficients[0] * 0.282095
         + sh.coefficients[1] * 0.488603 * dir.y
         + sh.coefficients[2] * 0.488603 * dir.z
         + sh.coefficients[3] * 0.488603 * dir.x
         + sh.coefficients[4] * 1.092548 * dir.x * dir.y
         + sh.coefficients[5] * 1.092548 * dir.y * dir.z
         + sh.coefficients[6] * 0.315392 * (3.0 * dir.z * dir.z - 1.0)
         + sh.coefficients[7] * 1.092548 * dir.x * dir.z
         + sh.coefficients[8] * 0.546274 * (dir.x * dir.x - dir.y * dir.y);
}


float EvaluateSH(SH4 sh, vec3 dir) {
    return sh.coefficients[0] * 0.282095;
         + sh.coefficients[1] * 0.488603 * dir.y;
         + sh.coefficients[2] * 0.488603 * dir.z;
         + sh.coefficients[3] * 0.488603 * dir.x;
}


vec3 EvaluateSH(SH4Color sh, vec3 dir) {
    return sh.coefficients[0] * 0.282095;
         + sh.coefficients[1] * 0.488603 * dir.y;
         + sh.coefficients[2] * 0.488603 * dir.z;
         + sh.coefficients[3] * 0.488603 * dir.x;
}