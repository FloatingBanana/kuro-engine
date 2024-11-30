uniform mat4 uWorldMatrix;
uniform mat3 uInverseTransposedWorldMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjMatrix;
uniform mat4 uViewProjMatrix;

uniform float uNearPlane;
uniform float uFarPlane;

uniform mat4 uInvViewMatrix;
uniform mat4 uInvProjMatrix;
uniform mat4 uInvViewProjMatrix;

uniform bool uHasAnimation;
uniform mat4 uBoneMatrices[MAX_BONE_COUNT];
uniform vec4 uBoneQuaternions[MAX_BONE_COUNT*2];

uniform vec3 uViewPosition;
uniform vec3 uViewDirection;

uniform sampler2D uDepthBuffer;
uniform sampler2D uColorBuffer;
uniform sampler2D uBRDF_LUT;

uniform bool uIsCanvasActive;
uniform float uTime;