uniform mat4 uWorldMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjMatrix;
uniform mat4 uViewProjMatrix;

uniform float uNearPlane;
uniform float uFarPlane;

uniform mat4 uInvViewMatrix;
uniform mat4 uInvProjMatrix;
uniform mat4 uInvViewProjMatrix;

uniform mat4 uPrevTransform;
uniform mat4 uBoneMatrices[MAX_BONE_COUNT];

uniform vec3 uViewPosition;
uniform vec3 uViewDirection;

uniform sampler2D uDepthBuffer;
uniform sampler2D uVelocityBuffer;
uniform sampler2D uColorBuffer;
uniform sampler2D uGNormal;
uniform sampler2D uGAlbedoSpecular;

uniform bool uIsCanvasActive;
uniform float uTime;