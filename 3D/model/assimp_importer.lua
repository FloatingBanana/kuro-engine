local Matrix     = require "engine.math.matrix"
local Stack      = require "engine.collections.stack"
local Vector3    = require "engine.math.vector3"
local Vector2    = require "engine.math.vector2"
local Quaternion = require "engine.math.quaternion"
local bit        = require "bit"
local ffi        = require "ffi"
local newtable   = require "table.new"


local ENABLE_LOGGING = false


-- Load definitions
local def = love.filesystem.read("string", "engine/3D/model/assimp_cdef.h")
ffi.cdef(def)


-- Load assimp shared library
local libpath =
    package.searchpath("assimp", package.cpath) or
    package.searchpath("libassimp-5", package.cpath) or
    package.searchpath("assimp-vc143-mt", package.cpath)

local Assimp = ffi.load(libpath)


-- A few pointers
local aiStringPtr = ffi.new("struct aiString[1]")
local aiColor4Ptr = ffi.new("struct aiColor4D[1]")
local aiRealPtr = ffi.new("ai_real[1]")
local uintPtr = ffi.new("unsigned int[1]")


-- Logging functionality
local aiLogStream = ffi.new("struct aiLogStream[1]")
aiLogStream[0].callback = function(message, user)
    io.write(ffi.string(message))
end





-- Custom file IO callbacks
local files = {} ---@type table<string, love.File>
local fileindex = 1

local readProc = ffi.cast("aiFileReadProc", function(aiFile, data, size, count)
    local content, contSize = files[aiFile.UserData[0]]:read("data", tonumber(size*count))

    ffi.copy(data, content:getFFIPointer(), contSize)
    return contSize / size
end)

local writeProc = ffi.cast("aiFileWriteProc", function(aiFile, data, size, count)
    success, err = files[aiFile.UserData[0]]:write(ffi.string(data), tonumber(size*count))
    return success and count or 0
end)

local tellProc = ffi.cast("aiFileTellProc", function(aiFile)
    return files[aiFile.UserData[0]]:tell()
end)

local fileSizeProc = ffi.cast("aiFileTellProc", function(aiFile)
    return files[aiFile.UserData[0]]:getSize()
end)

local flushProc = ffi.cast("aiFileFlushProc", function(aiFile)
    files[aiFile.UserData[0]]:flush()
end)

local seekProc = ffi.cast("aiFileSeek", function(aiFile, offset, origin)
    local file = files[aiFile.UserData[0]]
    local pos =
        origin == Assimp.aiOrigin_SET and offset or
        origin == Assimp.aiOrigin_CUR and file:tell() + offset or
        file:getSize() - offset

    return file:seek(tonumber(pos)) and Assimp.aiReturn_SUCCESS or Assimp.aiReturn_FAILURE
end)


local defaultAiFileIO = ffi.new("struct aiFileIO[1]", {{
    OpenProc = function(aiFileIO, path, mode)
        local aiFile = ffi.new("struct aiFile[1]")

        aiFile[0].ReadProc = readProc
        aiFile[0].WriteProc = writeProc
        aiFile[0].TellProc = tellProc
        aiFile[0].FileSizeProc = fileSizeProc
        aiFile[0].SeekProc = seekProc
        aiFile[0].FlushProc = flushProc
        aiFile[0].UserData = ffi.new("char[1]", fileindex)

        local openmode = ffi.string(mode)
        openmode =
            openmode == "rb" and "r" or
            openmode == "wb" and "w" or
            openmode == "ab" and "a" or
            openmode

        local file, err = love.filesystem.newFile(ffi.string(path), openmode)
        assert(file, err)

        files[fileindex] = file
        fileindex = fileindex + 1
        return aiFile
    end,

    CloseProc = function(aiFileIO, aiFile)
        files[aiFile.UserData[0]]:close()
        files[aiFile.UserData[0]] = nil
    end
}})



-- Helpers
local function checkSuccess(aiReturn)
    assert(aiReturn ~= Assimp.aiReturn_OUTOFMEMORY, "Out of memory while loading model")
    return aiReturn == Assimp.aiReturn_SUCCESS
end

local function readString(aiString)
    return ffi.string(aiString.data, aiString.length)
end

local function readMatrix4x4(mat)
    return Matrix(
        mat.a1, mat.b1, mat.c1, mat.d1,
        mat.a2, mat.b2, mat.c2, mat.d2,
        mat.a3, mat.b3, mat.c3, mat.d3,
        mat.a4, mat.b4, mat.c4, mat.d4
    )
end

local function readVector3(aiVec)
    return Vector3(aiVec.x, aiVec.y, aiVec.z)
end

local function readVector2(aiVec)
    return Vector2(aiVec.x, aiVec.y)
end

local function readColor3(aiColor)
    return {aiColor.r, aiColor.g, aiColor.b}
end

local function getMaterialTexture(aiMat, basePath, aiTextureType)
    local relativePath = checkSuccess(Assimp.aiGetMaterialTexture(aiMat, aiTextureType, 0, aiStringPtr, nil, nil, nil, nil, nil, nil)) and readString(aiStringPtr[0]) or nil

    if relativePath then
        return basePath:match("^.*/")..relativePath:gsub("%%20", " ")
    end
    return nil
end

local function getMaterialValue(aiMat, property, type)
    uintPtr[0] = 1

    if type == "float" then
        return checkSuccess(Assimp.aiGetMaterialFloatArray(aiMat, property, 0, 0, aiRealPtr, uintPtr)) and aiRealPtr[0] or nil
    elseif type == "string" then
        return checkSuccess(Assimp.aiGetMaterialString(aiMat, property, 0, 0, aiStringPtr)) and readString(aiStringPtr[0]) or nil
    end
end





local function importer(path, triangulate, flipUVs, removeUnusedMaterials, optimizeGraph)
    if ENABLE_LOGGING then
        Assimp.aiEnableVerboseLogging(true)
        Assimp.aiAttachLogStream(aiLogStream)
    end


    -- Setup scene postprocessing flags
    ---@diagnostic disable: param-type-mismatch
    local flags = bit.bor(
        Assimp.aiProcess_OptimizeMeshes,
        Assimp.aiProcess_SortByPType,
        Assimp.aiProcess_ValidateDataStructure,
        Assimp.aiProcess_JoinIdenticalVertices,
        Assimp.aiProcess_LimitBoneWeights,
        Assimp.aiProcess_ImproveCacheLocality,
        Assimp.aiProcess_PopulateArmatureData,
        Assimp.aiProcess_FindDegenerates,
        Assimp.aiProcess_FindInvalidData,
        Assimp.aiProcess_GenSmoothNormals,
        Assimp.aiProcess_CalcTangentSpace,
        Assimp.aiProcess_GenUVCoords,
        Assimp.aiProcess_TransformUVCoords,
        Assimp.aiProcess_SplitLargeMeshes,

        removeUnusedMaterials and Assimp.aiProcess_RemoveRedundantMaterials or 0x0,
        optimizeGraph         and Assimp.aiProcess_OptimizeGraph            or 0x0,
        triangulate           and Assimp.aiProcess_Triangulate              or 0x0,
        flipUVs               and Assimp.aiProcess_FlipUVs                  or 0x0
    )
    ---@diagnostic enable: param-type-mismatch


    -- Import scene
    local aiScene = Assimp.aiImportFileEx(path, flags, defaultAiFileIO)
    if aiScene == nil then
        error(ffi.string(Assimp.aiGetErrorString()))
    end


    local armatureBoneIDs = {}
    local scene = {
        rootNode   = nil,
        bones      = {},
        materials  = newtable(0, aiScene.mNumMaterials),
        animations = newtable(0, aiScene.mNumAnimations),
        meshParts  = newtable(0, aiScene.mNumMeshes),
        lights     = newtable(0, aiScene.mNumLights),
        cameras    = newtable(0, aiScene.mNumCameras),
        armatures  = newtable(0, aiScene.mNumSkeletons)
    }


    -- Load materials
    for i=1, aiScene.mNumMaterials do
        local aiMat = aiScene.mMaterials[i-1]
        local name = getMaterialValue(aiMat, "?mat.name", "string") or ""

        scene.materials[name] = {
            name         = name,
            tex_diffuse  = getMaterialTexture(aiMat, path, Assimp.aiTextureType_DIFFUSE),
            tex_specular = getMaterialTexture(aiMat, path, Assimp.aiTextureType_SPECULAR),
            tex_emissive = getMaterialTexture(aiMat, path, Assimp.aiTextureType_EMISSIVE),
            tex_normals  = getMaterialTexture(aiMat, path, Assimp.aiTextureType_NORMALS),

            basecolor          = getMaterialValue(aiMat, "$clr.base"             , "color") or {1,1,1,1},
            diffusecolor       = getMaterialValue(aiMat, "$clr.diffuse"          , "color") or {1,1,1,1},
            specularcolor      = getMaterialValue(aiMat, "$clr.specular"         , "color") or {1,1,1,1},
            emissivecolor      = getMaterialValue(aiMat, "$clr.emissive"         , "color") or {1,1,1,1},
            metallic           = getMaterialValue(aiMat, "$mat.metallicFactor"   , "float") or 0,
            roughness          = getMaterialValue(aiMat, "$mat.roughnessFactor"  , "float") or 1,
            shininess          = getMaterialValue(aiMat, "$mat.shininess"        , "float") or 1,
            opacity            = getMaterialValue(aiMat, "$mat.opacity"          , "float") or 1,
            reflectivity       = getMaterialValue(aiMat, "$mat.reflectivity"     , "float") or 0,
            refraction         = getMaterialValue(aiMat, "$mat.emissiveIntensity", "float") or 0,
            emissive_intensity = getMaterialValue(aiMat, "$mat.refracti"         , "float") or 0,
        }
    end



    -- Load cameras
    for c=1, aiScene.mNumCameras do
        local aiCamera = aiScene.mCameras[c-1]
        local name = readString(aiCamera.mName)

        scene.cameras[name] = {
            name       = name,
            position   = readVector3(aiCamera.mPosition),
            up         = readVector3(aiCamera.mUp),
            target     = readVector3(aiCamera.mLookAt),
            fov        = aiCamera.mHorizontalFOV,
            near       = aiCamera.mClipPlaneNear,
            far        = aiCamera.mClipPlaneFar,
            aspect     = aiCamera.mAspect,
            orthoWidth = aiCamera.mOrthographicWidth,
        }
    end


    -- Load lights
    for l=1, aiScene.mNumLights do
        local aiLight = aiScene.mLights[l-1]
        local name = readString(aiLight.mName)
        local lightType =
            aiLight.mType == Assimp.aiLightSource_UNDEFINED   and "undefined"   or
            aiLight.mType == Assimp.aiLightSource_DIRECTIONAL and "directional" or
            aiLight.mType == Assimp.aiLightSource_SPOT        and "spot"        or
            aiLight.mType == Assimp.aiLightSource_POINT       and "point"       or
            aiLight.mType == Assimp.aiLightSource_AMBIENT     and "ambient"     or
            aiLight.mType == Assimp.aiLightSource_AREA        and "area"        or nil

        scene.lights[name] = {
            name       = name,
            type       = lightType,
            position   = readVector3(aiLight.mPosition),
            direction  = readVector3(aiLight.mDirection),
            up         = readVector3(aiLight.mUp),

            ambient    = readColor3(aiLight.mColorAmbient),
            diffuse    = readColor3(aiLight.mColorDiffuse),
            specular   = readColor3(aiLight.mColorSpecular),

            constant   = aiLight.mAttenuationConstant,
            linear     = aiLight.mAttenuationLinear,
            quadratic  = aiLight.mAttenuationQuadratic,

            innerCone  = aiLight.mAngleInnerCone,
            outerCone  = aiLight.mAngleOuterCone,

            size       = readVector2(aiLight.mSize)
        }
    end



    -- Get mesh parts and bones
    for m=1, aiScene.mNumMeshes do
        local aiMesh = aiScene.mMeshes[m-1]
        local part = {
            name     = readString(aiMesh.mName),
            material = getMaterialValue(aiScene.mMaterials[aiMesh.mMaterialIndex], "?mat.name", "string"),
            verts    = newtable(aiMesh.mNumVertices, 0),
            indices  = newtable(aiMesh.mNumVertices, 0)
        }

        -- Vertices
        for v=1, aiMesh.mNumVertices do
            local vi = v-1
            part.verts[v] = {
                position  = readVector3(aiMesh.mVertices[vi]),
                normal    = aiMesh.mNormals    ~= nil and readVector3(aiMesh.mNormals[vi])    or Vector3(),
                tangent   = aiMesh.mTangents   ~= nil and readVector3(aiMesh.mTangents[vi])   or Vector3(),
                bitangent = aiMesh.mBitangents ~= nil and readVector3(aiMesh.mBitangents[vi]) or Vector3(),
                uv        = readVector2(aiMesh.mTextureCoords[0][vi]),
                boneIds   = {-1,-1,-1,-1},
                weights   = {0,0,0,0}
            }
        end

        -- Indices
        local ii = 1
        for f=1, aiMesh.mNumFaces do
            local aiFace = aiMesh.mFaces[f-1]

            for i=1, aiFace.mNumIndices do
                part.indices[ii] = aiFace.mIndices[i-1]+1
                ii = ii+1
            end
        end

        -- Bones
        for b=1, aiMesh.mNumBones do
            local aiBone = aiMesh.mBones[b-1]
            local boneName = readString(aiBone.mName)
            local armatureName = readString(aiBone.mArmature.mName)
            local armature = scene.armatures[armatureName] or {}
            local bone = armature[boneName]

            scene.armatures[armatureName] = armature

            if not bone then
                bone = {
                    id = armatureBoneIDs[armatureName] or 0,
                    offset = readMatrix4x4(aiBone.mOffsetMatrix),
                }

                armature[boneName] = bone
                armatureBoneIDs[armatureName] = bone.id + 1
            end

            -- Assign bone weights to vertices
            for w=1, aiBone.mNumWeights do
                local aiWeight = aiBone.mWeights[w-1]
                local vert = part.verts[aiWeight.mVertexId+1]

                for i=1, 4 do
                    if vert.boneIds[i] == -1 then
                        vert.boneIds[i] = bone.id
                        vert.weights[i] = aiWeight.mWeight
                        break
                    end
                end
            end
        end

        scene.meshParts[part.name] = part
    end


    local loadNode
    loadNode = function(aiNode)
        local node = {
            name      = readString(aiNode.mName),
            meshParts = nil,
            children  = {},
            transform = readMatrix4x4(aiNode.mTransformation),
        }

        -- Load mesh part names attached to this node
        if aiNode.mNumMeshes > 0 then
            node.meshParts = {}

            for m=1, aiNode.mNumMeshes do
                local aiMesh = aiScene.mMeshes[aiNode.mMeshes[m-1]]
                node.meshParts[m] = readString(aiMesh.mName)
            end
        end

        -- Load children
        for c=1, aiNode.mNumChildren do
            table.insert(node.children, loadNode(aiNode.mChildren[c-1]))
        end

        return node
    end

    scene.rootNode = loadNode(aiScene.mRootNode)


    -- Load animations
    for a=1, aiScene.mNumAnimations do
        local aiAnim = aiScene.mAnimations[a-1]
        local animation = {
            name     = readString(aiAnim.mName),
            duration = aiAnim.mDuration,
            fps      = aiAnim.mTicksPerSecond,
            nodes    = newtable(0, aiAnim.mNumChannels)
        }

        -- Animation nodes (channels)
        for n=1, aiAnim.mNumChannels do
            local aiNodeAnim = aiAnim.mChannels[n-1]
            local animNode = {
                name         = readString(aiNodeAnim.mNodeName),
                positionKeys = newtable(aiNodeAnim.mNumPositionKeys, 0),
                scaleKeys    = newtable(aiNodeAnim.mNumScalingKeys,  0),
                rotationKeys = newtable(aiNodeAnim.mNumRotationKeys, 0),
            }

            for k=1, aiNodeAnim.mNumPositionKeys do
                local aiKey = aiNodeAnim.mPositionKeys[k-1]
                animNode.positionKeys[k] = {time = aiKey.mTime, value = readVector3(aiKey.mValue)}
            end

            for k=1, aiNodeAnim.mNumRotationKeys do
                local aiKey = aiNodeAnim.mRotationKeys[k-1]
                animNode.rotationKeys[k] = {time = aiKey.mTime, value = Quaternion(aiKey.mValue.x, aiKey.mValue.y, aiKey.mValue.z, aiKey.mValue.w)}
            end

            for k=1, aiNodeAnim.mNumScalingKeys do
                local aiKey = aiNodeAnim.mScalingKeys[k-1]
                animNode.scaleKeys[k] = {time = aiKey.mTime, value = readVector3(aiKey.mValue)}
            end

            animation.nodes[animNode.name] = animNode
        end

        scene.animations[animation.name] = animation
    end

    Assimp.aiReleaseImport(aiScene)
    Assimp.aiDetachAllLogStreams()


    return scene
end

return importer