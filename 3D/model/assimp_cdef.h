enum aiComponent
{
    aiComponent_NORMALS = 0x2u,
    aiComponent_TANGENTS_AND_BITANGENTS = 0x4u,
    aiComponent_COLORS = 0x8,
    aiComponent_TEXCOORDS = 0x10,
    aiComponent_BONEWEIGHTS = 0x20,
    aiComponent_ANIMATIONS = 0x40,
    aiComponent_TEXTURES = 0x80,
    aiComponent_LIGHTS = 0x100,
    aiComponent_CAMERAS = 0x200,
    aiComponent_MESHES = 0x400,
    aiComponent_MATERIALS = 0x800,
};
typedef float ai_real;
typedef signed int ai_int;
typedef unsigned int ai_uint;
struct aiVector2D {
    ai_real x, y;
};
struct aiVector3D {
    ai_real x, y, z;
};
struct aiColor4D {
    ai_real r, g, b, a;
};
struct aiMatrix3x3 {
    ai_real a1, a2, a3;
    ai_real b1, b2, b3;
    ai_real c1, c2, c3;
};
struct aiMatrix4x4 {
    ai_real a1, a2, a3, a4;
    ai_real b1, b2, b3, b4;
    ai_real c1, c2, c3, c4;
    ai_real d1, d2, d3, d4;
};
struct aiQuaternion {
    ai_real w, x, y, z;
};
typedef int32_t ai_int32;
typedef uint32_t ai_uint32;
struct aiPlane {
    ai_real a, b, c, d;
};
struct aiRay {
    struct aiVector3D pos, dir;
};
struct aiColor3D {
    ai_real r, g, b;
};
struct aiString {
    ai_uint32 length;
    char data[1024];
};
typedef enum aiReturn {
    aiReturn_SUCCESS = 0x0,
    aiReturn_FAILURE = -0x1,
    aiReturn_OUTOFMEMORY = -0x3,
} aiReturn;
enum aiOrigin {
    aiOrigin_SET = 0x0,
    aiOrigin_CUR = 0x1,
    aiOrigin_END = 0x2,
};
enum aiDefaultLogStream {
    aiDefaultLogStream_FILE = 0x1,
    aiDefaultLogStream_STDOUT = 0x2,
    aiDefaultLogStream_STDERR = 0x4,
    aiDefaultLogStream_DEBUGGER = 0x8,
};
struct aiMemoryInfo {
    unsigned int textures;
    unsigned int materials;
    unsigned int meshes;
    unsigned int nodes;
    unsigned int animations;
    unsigned int cameras;
    unsigned int lights;
    unsigned int total;
};
struct aiFileIO;
struct aiFile;
typedef size_t (*aiFileWriteProc) (struct aiFile*, const char*, size_t, size_t);
typedef size_t (*aiFileReadProc) (struct aiFile*, char*, size_t,size_t);
typedef size_t (*aiFileTellProc) (struct aiFile*);
typedef void (*aiFileFlushProc) (struct aiFile*);
typedef enum aiReturn (*aiFileSeek) (struct aiFile*, size_t, enum aiOrigin);
typedef struct aiFile* (*aiFileOpenProc) (struct aiFileIO*, const char*, const char*);
typedef void (*aiFileCloseProc) (struct aiFileIO*, struct aiFile*);
typedef char* aiUserData;
struct aiFileIO
{
    aiFileOpenProc OpenProc;
    aiFileCloseProc CloseProc;
    aiUserData UserData;
};
struct aiFile {
    aiFileReadProc ReadProc;
    aiFileWriteProc WriteProc;
    aiFileTellProc TellProc;
    aiFileTellProc FileSizeProc;
    aiFileSeek SeekProc;
    aiFileFlushProc FlushProc;
    aiUserData UserData;
};
enum aiImporterFlags {
    aiImporterFlags_SupportTextFlavour = 0x1,
    aiImporterFlags_SupportBinaryFlavour = 0x2,
    aiImporterFlags_SupportCompressedFlavour = 0x4,
    aiImporterFlags_LimitedSupport = 0x8,
    aiImporterFlags_Experimental = 0x10
};
struct aiImporterDesc {
    const char *mName;
    const char *mAuthor;
    const char *mMaintainer;
    const char *mComments;
    unsigned int mFlags;
    unsigned int mMinMajor;
    unsigned int mMinMinor;
    unsigned int mMaxMajor;
    unsigned int mMaxMinor;
    const char *mFileExtensions;
};
const struct aiImporterDesc *aiGetImporterDesc(const char *extension);
struct aiAABB {
    struct aiVector3D mMin;
    struct aiVector3D mMax;
};
struct aiTexel {
    unsigned char b,g,r,a;
} PACK_STRUCT;
struct aiTexture {
    unsigned int mWidth;
    unsigned int mHeight;
    char achFormatHint[ 9 ];
    struct aiTexel* pcData;
    struct aiString mFilename;
};
struct aiFace {
    unsigned int mNumIndices;
    unsigned int *mIndices;
};
struct aiVertexWeight {
    unsigned int mVertexId;
    ai_real mWeight;
};
struct aiNode;
struct aiBone {
    struct aiString mName;
    unsigned int mNumWeights;
    struct aiNode *mArmature;
    struct aiNode *mNode;
    struct aiVertexWeight *mWeights;
    struct aiMatrix4x4 mOffsetMatrix;
};
enum aiPrimitiveType {
    aiPrimitiveType_POINT = 0x1,
    aiPrimitiveType_LINE = 0x2,
    aiPrimitiveType_TRIANGLE = 0x4,
    aiPrimitiveType_POLYGON = 0x8,
    aiPrimitiveType_NGONEncodingFlag = 0x10,
};
struct aiAnimMesh {
    struct aiString mName;
    struct aiVector3D *mVertices;
    struct aiVector3D *mNormals;
    struct aiVector3D *mTangents;
    struct aiVector3D *mBitangents;
    struct aiColor4D *mColors[0x8];
    struct aiVector3D *mTextureCoords[0x8];
    unsigned int mNumVertices;
    float mWeight;
};
enum aiMorphingMethod {
    aiMorphingMethod_VERTEX_BLEND = 0x1,
    aiMorphingMethod_MORPH_NORMALIZED = 0x2,
    aiMorphingMethod_MORPH_RELATIVE = 0x3,
};
struct aiMesh {
    unsigned int mPrimitiveTypes;
    unsigned int mNumVertices;
    unsigned int mNumFaces;
    struct aiVector3D *mVertices;
    struct aiVector3D *mNormals;
    struct aiVector3D *mTangents;
    struct aiVector3D *mBitangents;
    struct aiColor4D *mColors[0x8];
    struct aiVector3D *mTextureCoords[0x8];
    unsigned int mNumUVComponents[0x8];
    struct aiFace *mFaces;
    unsigned int mNumBones;
    struct aiBone **mBones;
    unsigned int mMaterialIndex;
    struct aiString mName;
    unsigned int mNumAnimMeshes;
    struct aiAnimMesh **mAnimMeshes;
    unsigned int mMethod;
    struct aiAABB mAABB;
    struct aiString **mTextureCoordsNames;
};
struct aiSkeletonBone {
    int mParent;
    struct aiNode *mArmature;
    struct aiNode *mNode;
    unsigned int mNumnWeights;
    struct aiMesh *mMeshId;
    struct aiVertexWeight *mWeights;
    struct aiMatrix4x4 mOffsetMatrix;
    struct aiMatrix4x4 mLocalMatrix;
};
struct aiSkeleton {
    struct aiString mName;
    unsigned int mNumBones;
    struct aiSkeletonBone **mBones;
};
enum aiLightSourceType {
    aiLightSource_UNDEFINED = 0x0,
    aiLightSource_DIRECTIONAL = 0x1,
    aiLightSource_POINT = 0x2,
    aiLightSource_SPOT = 0x3,
    aiLightSource_AMBIENT = 0x4,
    aiLightSource_AREA = 0x5,
};
struct aiLight {
    struct aiString mName;
    enum aiLightSourceType mType;
    struct aiVector3D mPosition;
    struct aiVector3D mDirection;
    struct aiVector3D mUp;
    float mAttenuationConstant;
    float mAttenuationLinear;
    float mAttenuationQuadratic;
    struct aiColor3D mColorDiffuse;
    struct aiColor3D mColorSpecular;
    struct aiColor3D mColorAmbient;
    float mAngleInnerCone;
    float mAngleOuterCone;
    struct aiVector2D mSize;
};
struct aiCamera {
    struct aiString mName;
    struct aiVector3D mPosition;
    struct aiVector3D mUp;
    struct aiVector3D mLookAt;
    float mHorizontalFOV;
    float mClipPlaneNear;
    float mClipPlaneFar;
    float mAspect;
    float mOrthographicWidth;
};
enum aiTextureOp {
    aiTextureOp_Multiply = 0x0,
    aiTextureOp_Add = 0x1,
    aiTextureOp_Subtract = 0x2,
    aiTextureOp_Divide = 0x3,
    aiTextureOp_SmoothAdd = 0x4,
    aiTextureOp_SignedAdd = 0x5,
};
enum aiTextureMapMode {
    aiTextureMapMode_Wrap = 0x0,
    aiTextureMapMode_Clamp = 0x1,
    aiTextureMapMode_Decal = 0x3,
    aiTextureMapMode_Mirror = 0x2,
};
enum aiTextureMapping {
    aiTextureMapping_UV = 0x0,
    aiTextureMapping_SPHERE = 0x1,
    aiTextureMapping_CYLINDER = 0x2,
    aiTextureMapping_BOX = 0x3,
    aiTextureMapping_PLANE = 0x4,
    aiTextureMapping_OTHER = 0x5,
};
enum aiTextureType {
    aiTextureType_NONE = 0,
    aiTextureType_DIFFUSE = 1,
    aiTextureType_SPECULAR = 2,
    aiTextureType_AMBIENT = 3,
    aiTextureType_EMISSIVE = 4,
    aiTextureType_HEIGHT = 5,
    aiTextureType_NORMALS = 6,
    aiTextureType_SHININESS = 7,
    aiTextureType_OPACITY = 8,
    aiTextureType_DISPLACEMENT = 9,
    aiTextureType_LIGHTMAP = 10,
    aiTextureType_REFLECTION = 11,
    aiTextureType_BASE_COLOR = 12,
    aiTextureType_NORMAL_CAMERA = 13,
    aiTextureType_EMISSION_COLOR = 14,
    aiTextureType_METALNESS = 15,
    aiTextureType_DIFFUSE_ROUGHNESS = 16,
    aiTextureType_AMBIENT_OCCLUSION = 17,
    aiTextureType_SHEEN = 19,
    aiTextureType_CLEARCOAT = 20,
    aiTextureType_TRANSMISSION = 21,
    aiTextureType_UNKNOWN = 18,
};
const char *aiTextureTypeToString(enum aiTextureType in);
enum aiShadingMode {
    aiShadingMode_Flat = 0x1,
    aiShadingMode_Gouraud = 0x2,
    aiShadingMode_Phong = 0x3,
    aiShadingMode_Blinn = 0x4,
    aiShadingMode_Toon = 0x5,
    aiShadingMode_OrenNayar = 0x6,
    aiShadingMode_Minnaert = 0x7,
    aiShadingMode_CookTorrance = 0x8,
    aiShadingMode_NoShading = 0x9,
    aiShadingMode_Unlit = aiShadingMode_NoShading,
    aiShadingMode_Fresnel = 0xa,
    aiShadingMode_PBR_BRDF = 0xb,
};
enum aiTextureFlags {
    aiTextureFlags_Invert = 0x1,
    aiTextureFlags_UseAlpha = 0x2,
    aiTextureFlags_IgnoreAlpha = 0x4,
};
enum aiBlendMode {
    aiBlendMode_Default = 0x0,
    aiBlendMode_Additive = 0x1,
};
struct aiUVTransform {
    struct aiVector2D mTranslation;
    struct aiVector2D mScaling;
    ai_real mRotation;
};
enum aiPropertyTypeInfo {
    aiPTI_Float = 0x1,
    aiPTI_Double = 0x2,
    aiPTI_String = 0x3,
    aiPTI_Integer = 0x4,
    aiPTI_Buffer = 0x5,
};
struct aiMaterialProperty {
    struct aiString mKey;
    unsigned int mSemantic;
    unsigned int mIndex;
    unsigned int mDataLength;
    enum aiPropertyTypeInfo mType;
    char *mData;
};
struct aiMaterial
{
    struct aiMaterialProperty **mProperties;
    unsigned int mNumProperties;
    unsigned int mNumAllocated;
};
enum aiReturn aiGetMaterialProperty(
        const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        const struct aiMaterialProperty **pPropOut);
enum aiReturn aiGetMaterialFloatArray(
        const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        ai_real *pOut,
        unsigned int *pMax);
inline aiReturn aiGetMaterialFloat(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        ai_real *pOut) {
    return aiGetMaterialFloatArray(pMat, pKey, type, index, pOut, (unsigned int *)0x0);
}
enum aiReturn aiGetMaterialIntegerArray(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        int *pOut,
        unsigned int *pMax);
inline aiReturn aiGetMaterialInteger(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        int *pOut) {
    return aiGetMaterialIntegerArray(pMat, pKey, type, index, pOut, (unsigned int *)0x0);
}
enum aiReturn aiGetMaterialColor(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        struct aiColor4D *pOut);
enum aiReturn aiGetMaterialUVTransform(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        struct aiUVTransform *pOut);
enum aiReturn aiGetMaterialString(const struct aiMaterial *pMat,
        const char *pKey,
        unsigned int type,
        unsigned int index,
        struct aiString *pOut);
unsigned int aiGetMaterialTextureCount(const struct aiMaterial *pMat,
        enum aiTextureType type);
enum aiReturn aiGetMaterialTexture(const struct aiMaterial *mat,
        enum aiTextureType type,
        unsigned int index,
        struct aiString *path,
        enum aiTextureMapping *mapping ,
        unsigned int *uvindex ,
        ai_real *blend ,
        enum aiTextureOp *op ,
        enum aiTextureMapMode *mapmode ,
        unsigned int *flags );
struct aiVectorKey {
    double mTime;
    struct aiVector3D mValue;
};
struct aiQuatKey {
    double mTime;
    struct aiQuaternion mValue;
};
struct aiMeshKey {
    double mTime;
    unsigned int mValue;
};
struct aiMeshMorphKey {
    double mTime;
    unsigned int *mValues;
    double *mWeights;
    unsigned int mNumValuesAndWeights;
};
enum aiAnimBehaviour {
    aiAnimBehaviour_DEFAULT = 0x0,
    aiAnimBehaviour_CONSTANT = 0x1,
    aiAnimBehaviour_LINEAR = 0x2,
    aiAnimBehaviour_REPEAT = 0x3,
};
struct aiNodeAnim {
    struct aiString mNodeName;
    unsigned int mNumPositionKeys;
    struct aiVectorKey *mPositionKeys;
    unsigned int mNumRotationKeys;
    struct aiQuatKey *mRotationKeys;
    unsigned int mNumScalingKeys;
    struct aiVectorKey *mScalingKeys;
    enum aiAnimBehaviour mPreState;
    enum aiAnimBehaviour mPostState;
};
struct aiMeshAnim {
    struct aiString mName;
    unsigned int mNumKeys;
    struct aiMeshKey *mKeys;
};
struct aiMeshMorphAnim {
    struct aiString mName;
    unsigned int mNumKeys;
    struct aiMeshMorphKey *mKeys;
};
struct aiAnimation {
    struct aiString mName;
    double mDuration;
    double mTicksPerSecond;
    unsigned int mNumChannels;
    struct aiNodeAnim **mChannels;
    unsigned int mNumMeshChannels;
    struct aiMeshAnim **mMeshChannels;
    unsigned int mNumMorphMeshChannels;
    struct aiMeshMorphAnim **mMorphMeshChannels;
};
typedef enum aiMetadataType {
    AI_BOOL = 0,
    AI_INT32 = 1,
    AI_UINT64 = 2,
    AI_FLOAT = 3,
    AI_DOUBLE = 4,
    AI_AISTRING = 5,
    AI_AIVECTOR3D = 6,
    AI_AIMETADATA = 7,
    AI_META_MAX = 8,
} aiMetadataType;
struct aiMetadataEntry {
    aiMetadataType mType;
    void *mData;
};
struct aiMetadata {
    unsigned int mNumProperties;
    struct aiString *mKeys;
    struct aiMetadataEntry *mValues;
};
struct aiNode {
    struct aiString mName;
    struct aiMatrix4x4 mTransformation;
    struct aiNode* mParent;
    unsigned int mNumChildren;
    struct aiNode** mChildren;
    unsigned int mNumMeshes;
    unsigned int* mMeshes;
    struct aiMetadata* mMetaData;
};
struct aiScene
{
    unsigned int mFlags;
    struct aiNode* mRootNode;
    unsigned int mNumMeshes;
    struct aiMesh** mMeshes;
    unsigned int mNumMaterials;
    struct aiMaterial** mMaterials;
    unsigned int mNumAnimations;
    struct aiAnimation** mAnimations;
    unsigned int mNumTextures;
    struct aiTexture** mTextures;
    unsigned int mNumLights;
    struct aiLight** mLights;
    unsigned int mNumCameras;
    struct aiCamera** mCameras;
    struct aiMetadata* mMetaData;
    struct aiString mName;
    unsigned int mNumSkeletons;
    struct aiSkeleton **mSkeletons;
    char* mPrivate;
};
struct aiScene;
struct aiFileIO;
typedef void (*aiLogStreamCallback)(const char * , char * );
struct aiLogStream {
    aiLogStreamCallback callback;
    char *user;
};
struct aiPropertyStore {
    char sentinel;
};
typedef int aiBool;
const struct aiScene *aiImportFile(
        const char *pFile,
        unsigned int pFlags);
const struct aiScene *aiImportFileEx(
        const char *pFile,
        unsigned int pFlags,
        struct aiFileIO *pFS);
const struct aiScene *aiImportFileExWithProperties(
        const char *pFile,
        unsigned int pFlags,
        struct aiFileIO *pFS,
        const struct aiPropertyStore *pProps);
const struct aiScene *aiImportFileFromMemory(
        const char *pBuffer,
        unsigned int pLength,
        unsigned int pFlags,
        const char *pHint);
const struct aiScene *aiImportFileFromMemoryWithProperties(
        const char *pBuffer,
        unsigned int pLength,
        unsigned int pFlags,
        const char *pHint,
        const struct aiPropertyStore *pProps);
const struct aiScene *aiApplyPostProcessing(
        const struct aiScene *pScene,
        unsigned int pFlags);
struct aiLogStream aiGetPredefinedLogStream(
        enum aiDefaultLogStream pStreams,
        const char *file);
void aiAttachLogStream(
        const struct aiLogStream *stream);
void aiEnableVerboseLogging(aiBool d);
enum aiReturn aiDetachLogStream(
        const struct aiLogStream *stream);
void aiDetachAllLogStreams(void);
void aiReleaseImport(
        const struct aiScene *pScene);
const char *aiGetErrorString(void);
aiBool aiIsExtensionSupported(
        const char *szExtension);
void aiGetExtensionList(
        struct aiString *szOut);
void aiGetMemoryRequirements(
        const struct aiScene *pIn,
        struct aiMemoryInfo *in);
struct aiPropertyStore *aiCreatePropertyStore(void);
void aiReleasePropertyStore(struct aiPropertyStore *p);
void aiSetImportPropertyInteger(
        struct aiPropertyStore *store,
        const char *szName,
        int value);
void aiSetImportPropertyFloat(
        struct aiPropertyStore *store,
        const char *szName,
        ai_real value);
void aiSetImportPropertyString(
        struct aiPropertyStore *store,
        const char *szName,
        const struct aiString *st);
void aiSetImportPropertyMatrix(
        struct aiPropertyStore *store,
        const char *szName,
        const struct aiMatrix4x4 *mat);
void aiCreateQuaternionFromMatrix(
        struct aiQuaternion *quat,
        const struct aiMatrix3x3 *mat);
void aiDecomposeMatrix(
        const struct aiMatrix4x4 *mat,
        struct aiVector3D *scaling,
        struct aiQuaternion *rotation,
        struct aiVector3D *position);
void aiTransposeMatrix4(
        struct aiMatrix4x4 *mat);
void aiTransposeMatrix3(
        struct aiMatrix3x3 *mat);
void aiTransformVecByMatrix3(
        struct aiVector3D *vec,
        const struct aiMatrix3x3 *mat);
void aiTransformVecByMatrix4(
        struct aiVector3D *vec,
        const struct aiMatrix4x4 *mat);
void aiMultiplyMatrix4(
        struct aiMatrix4x4 *dst,
        const struct aiMatrix4x4 *src);
void aiMultiplyMatrix3(
        struct aiMatrix3x3 *dst,
        const struct aiMatrix3x3 *src);
void aiIdentityMatrix3(
        struct aiMatrix3x3 *mat);
void aiIdentityMatrix4(
        struct aiMatrix4x4 *mat);
size_t aiGetImportFormatCount(void);
const struct aiImporterDesc *aiGetImportFormatDescription(size_t pIndex);
int aiVector2AreEqual(
        const struct aiVector2D *a,
        const struct aiVector2D *b);
int aiVector2AreEqualEpsilon(
        const struct aiVector2D *a,
        const struct aiVector2D *b,
        const float epsilon);
void aiVector2Add(
        struct aiVector2D *dst,
        const struct aiVector2D *src);
void aiVector2Subtract(
        struct aiVector2D *dst,
        const struct aiVector2D *src);
void aiVector2Scale(
        struct aiVector2D *dst,
        const float s);
void aiVector2SymMul(
        struct aiVector2D *dst,
        const struct aiVector2D *other);
void aiVector2DivideByScalar(
        struct aiVector2D *dst,
        const float s);
void aiVector2DivideByVector(
        struct aiVector2D *dst,
        struct aiVector2D *v);
float aiVector2Length(
        const struct aiVector2D *v);
float aiVector2SquareLength(
        const struct aiVector2D *v);
void aiVector2Negate(
        struct aiVector2D *dst);
float aiVector2DotProduct(
        const struct aiVector2D *a,
        const struct aiVector2D *b);
void aiVector2Normalize(
        struct aiVector2D *v);
int aiVector3AreEqual(
        const struct aiVector3D *a,
        const struct aiVector3D *b);
int aiVector3AreEqualEpsilon(
        const struct aiVector3D *a,
        const struct aiVector3D *b,
        const float epsilon);
int aiVector3LessThan(
        const struct aiVector3D *a,
        const struct aiVector3D *b);
void aiVector3Add(
        struct aiVector3D *dst,
        const struct aiVector3D *src);
void aiVector3Subtract(
        struct aiVector3D *dst,
        const struct aiVector3D *src);
void aiVector3Scale(
        struct aiVector3D *dst,
        const float s);
void aiVector3SymMul(
        struct aiVector3D *dst,
        const struct aiVector3D *other);
void aiVector3DivideByScalar(
        struct aiVector3D *dst,
        const float s);
void aiVector3DivideByVector(
        struct aiVector3D *dst,
        struct aiVector3D *v);
float aiVector3Length(
        const struct aiVector3D *v);
float aiVector3SquareLength(
        const struct aiVector3D *v);
void aiVector3Negate(
        struct aiVector3D *dst);
float aiVector3DotProduct(
        const struct aiVector3D *a,
        const struct aiVector3D *b);
void aiVector3CrossProduct(
        struct aiVector3D *dst,
        const struct aiVector3D *a,
        const struct aiVector3D *b);
void aiVector3Normalize(
        struct aiVector3D *v);
void aiVector3NormalizeSafe(
        struct aiVector3D *v);
void aiVector3RotateByQuaternion(
        struct aiVector3D *v,
        const struct aiQuaternion *q);
void aiMatrix3FromMatrix4(
        struct aiMatrix3x3 *dst,
        const struct aiMatrix4x4 *mat);
void aiMatrix3FromQuaternion(
        struct aiMatrix3x3 *mat,
        const struct aiQuaternion *q);
int aiMatrix3AreEqual(
        const struct aiMatrix3x3 *a,
        const struct aiMatrix3x3 *b);
int aiMatrix3AreEqualEpsilon(
        const struct aiMatrix3x3 *a,
        const struct aiMatrix3x3 *b,
        const float epsilon);
void aiMatrix3Inverse(
        struct aiMatrix3x3 *mat);
float aiMatrix3Determinant(
        const struct aiMatrix3x3 *mat);
void aiMatrix3RotationZ(
        struct aiMatrix3x3 *mat,
        const float angle);
void aiMatrix3FromRotationAroundAxis(
        struct aiMatrix3x3 *mat,
        const struct aiVector3D *axis,
        const float angle);
void aiMatrix3Translation(
        struct aiMatrix3x3 *mat,
        const struct aiVector2D *translation);
void aiMatrix3FromTo(
        struct aiMatrix3x3 *mat,
        const struct aiVector3D *from,
        const struct aiVector3D *to);
void aiMatrix4FromMatrix3(
        struct aiMatrix4x4 *dst,
        const struct aiMatrix3x3 *mat);
void aiMatrix4FromScalingQuaternionPosition(
        struct aiMatrix4x4 *mat,
        const struct aiVector3D *scaling,
        const struct aiQuaternion *rotation,
        const struct aiVector3D *position);
void aiMatrix4Add(
        struct aiMatrix4x4 *dst,
        const struct aiMatrix4x4 *src);
int aiMatrix4AreEqual(
        const struct aiMatrix4x4 *a,
        const struct aiMatrix4x4 *b);
int aiMatrix4AreEqualEpsilon(
        const struct aiMatrix4x4 *a,
        const struct aiMatrix4x4 *b,
        const float epsilon);
void aiMatrix4Inverse(
        struct aiMatrix4x4 *mat);
float aiMatrix4Determinant(
        const struct aiMatrix4x4 *mat);
int aiMatrix4IsIdentity(
        const struct aiMatrix4x4 *mat);
void aiMatrix4DecomposeIntoScalingEulerAnglesPosition(
        const struct aiMatrix4x4 *mat,
        struct aiVector3D *scaling,
        struct aiVector3D *rotation,
        struct aiVector3D *position);
void aiMatrix4DecomposeIntoScalingAxisAnglePosition(
        const struct aiMatrix4x4 *mat,
        struct aiVector3D *scaling,
        struct aiVector3D *axis,
        ai_real *angle,
        struct aiVector3D *position);
void aiMatrix4DecomposeNoScaling(
        const struct aiMatrix4x4 *mat,
        struct aiQuaternion *rotation,
        struct aiVector3D *position);
void aiMatrix4FromEulerAngles(
        struct aiMatrix4x4 *mat,
        float x, float y, float z);
void aiMatrix4RotationX(
        struct aiMatrix4x4 *mat,
        const float angle);
void aiMatrix4RotationY(
        struct aiMatrix4x4 *mat,
        const float angle);
void aiMatrix4RotationZ(
        struct aiMatrix4x4 *mat,
        const float angle);
void aiMatrix4FromRotationAroundAxis(
        struct aiMatrix4x4 *mat,
        const struct aiVector3D *axis,
        const float angle);
void aiMatrix4Translation(
        struct aiMatrix4x4 *mat,
        const struct aiVector3D *translation);
void aiMatrix4Scaling(
        struct aiMatrix4x4 *mat,
        const struct aiVector3D *scaling);
void aiMatrix4FromTo(
        struct aiMatrix4x4 *mat,
        const struct aiVector3D *from,
        const struct aiVector3D *to);
void aiQuaternionFromEulerAngles(
        struct aiQuaternion *q,
        float x, float y, float z);
void aiQuaternionFromAxisAngle(
        struct aiQuaternion *q,
        const struct aiVector3D *axis,
        const float angle);
void aiQuaternionFromNormalizedQuaternion(
        struct aiQuaternion *q,
        const struct aiVector3D *normalized);
int aiQuaternionAreEqual(
        const struct aiQuaternion *a,
        const struct aiQuaternion *b);
int aiQuaternionAreEqualEpsilon(
        const struct aiQuaternion *a,
        const struct aiQuaternion *b,
        const float epsilon);
void aiQuaternionNormalize(
        struct aiQuaternion *q);
void aiQuaternionConjugate(
        struct aiQuaternion *q);
void aiQuaternionMultiply(
        struct aiQuaternion *dst,
        const struct aiQuaternion *q);
void aiQuaternionInterpolate(
        struct aiQuaternion *dst,
        const struct aiQuaternion *start,
        const struct aiQuaternion *end,
        const float factor);
enum aiPostProcessSteps
{
    aiProcess_CalcTangentSpace = 0x1,
    aiProcess_JoinIdenticalVertices = 0x2,
    aiProcess_MakeLeftHanded = 0x4,
    aiProcess_Triangulate = 0x8,
    aiProcess_RemoveComponent = 0x10,
    aiProcess_GenNormals = 0x20,
    aiProcess_GenSmoothNormals = 0x40,
    aiProcess_SplitLargeMeshes = 0x80,
    aiProcess_PreTransformVertices = 0x100,
    aiProcess_LimitBoneWeights = 0x200,
    aiProcess_ValidateDataStructure = 0x400,
    aiProcess_ImproveCacheLocality = 0x800,
    aiProcess_RemoveRedundantMaterials = 0x1000,
    aiProcess_FixInfacingNormals = 0x2000,
    aiProcess_PopulateArmatureData = 0x4000,
    aiProcess_SortByPType = 0x8000,
    aiProcess_FindDegenerates = 0x10000,
    aiProcess_FindInvalidData = 0x20000,
    aiProcess_GenUVCoords = 0x40000,
    aiProcess_TransformUVCoords = 0x80000,
    aiProcess_FindInstances = 0x100000,
    aiProcess_OptimizeMeshes = 0x200000,
    aiProcess_OptimizeGraph = 0x400000,
    aiProcess_FlipUVs = 0x800000,
    aiProcess_FlipWindingOrder = 0x1000000,
    aiProcess_SplitByBoneCount = 0x2000000,
    aiProcess_Debone = 0x4000000,
    aiProcess_GlobalScale = 0x8000000,
    aiProcess_EmbedTextures = 0x10000000,
    aiProcess_ForceGenNormals = 0x20000000,
    aiProcess_DropNormals = 0x40000000,
    aiProcess_GenBoundingBoxes = 0x80000000
};
