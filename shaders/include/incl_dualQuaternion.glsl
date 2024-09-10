// https://github.com/brainexcerpts/Dual-Quaternion-Skinning-Sample-Codes/blob/master/dual_quat_cu.hpp

struct DualQuaternion {
    vec4 rotation;
    vec4 translation;
};


DualQuaternion dq_identity() {
    return DualQuaternion(vec4(0,0,0,1.0), vec4(0,0,0,0));
}


DualQuaternion dq_multiply(DualQuaternion dq1, DualQuaternion dq2) {
    return DualQuaternion(dq1.rotation*dq2.rotation, dq1.translation*dq2.translation);
}
DualQuaternion dq_multiply(DualQuaternion dq, float scalar) {
    return DualQuaternion(dq.rotation*scalar, dq.translation*scalar);
}


DualQuaternion dq_add(DualQuaternion dq1, DualQuaternion dq2) {
    return DualQuaternion(dq1.rotation+dq2.rotation, dq1.translation+dq2.translation);
}
DualQuaternion dq_add(DualQuaternion dq, float scalar) {
    return DualQuaternion(dq.rotation+scalar, dq.translation+scalar);
}


DualQuaternion dq_normalize(DualQuaternion dq) {
    float invLen = 1.0 / length(dq.rotation);
    return DualQuaternion(dq.rotation * invLen, dq.translation * invLen);
}


vec3 dq_rotate(DualQuaternion dq, vec3 v) {
    vec3 rotVec = dq.rotation.xyz;
    return v + cross(rotVec * 2.0, cross(rotVec, v) + v*dq.rotation.w);
}


vec3 dq_transform(DualQuaternion dq, vec3 v) {
    vec3 vrot = dq.rotation.xyz;
    vec3 vtra = dq.translation.xyz;

    vec3 trans = (vtra*dq.rotation.w - vrot*dq.translation.w + cross(vrot, vtra)) * 2.0;
    return dq_rotate(dq, v) + trans;
}


mat4 dq_transformationMatrix(DualQuaternion dq) {
    vec4 rot = dq.rotation;
    vec4 tr = dq.translation;

    float t0 = 2.0 * (-tr.w * rot.x + tr.x * rot.w - tr.y * rot.z + tr.z * rot.y);
	float t1 = 2.0 * (-tr.w * rot.y + tr.x * rot.z + tr.y * rot.w - tr.z * rot.x);
	float t2 = 2.0 * (-tr.w * rot.z - tr.x * rot.y + tr.y * rot.x + tr.z * rot.w);

	return mat4(
	    1.0 - (2.0 * rot.y * rot.y) - (2.0 * rot.z * rot.z),
	    (2.0 * rot.x * rot.y) + (2.0 * rot.w * rot.z),
	    (2.0 * rot.x * rot.z) - (2.0 * rot.w * rot.y),
	    0,
	    (2.0 * rot.x * rot.y) - (2.0 * rot.w * rot.z),
	    1.0 - (2.0 * rot.x * rot.x) - (2.0 * rot.z * rot.z),
	    (2.0 * rot.y * rot.z) + (2.0 * rot.w * rot.x),
	    0,
	    (2.0 * rot.x * rot.z) + (2.0 * rot.w * rot.y),
	    (2.0 * rot.y * rot.z) - (2.0 * rot.w * rot.x),
	    1.0 - (2.0 * rot.x * rot.x) - (2.0 * rot.y * rot.y),
	    0,
	    t0,
	    t1,
	    t2,
	    1.0
	);
}