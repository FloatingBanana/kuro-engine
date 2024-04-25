local Matrix     = require "engine.math.matrix"
local Stack      = require "engine.collections.stack"
local Vector3    = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local bit        = require("bit")
local ffi        = require("ffi")


-- Load definitions
local def, err = love.filesystem.read("string", "engine/3D/model/assimp_cdef.h")
assert(def, err)
ffi.cdef(def)


-- Load assimp shared library
local libpath =
    package.searchpath("assimp", package.cpath) or
    package.searchpath("libassimp-5", package.cpath) or
    package.searchpath("assimp-vc143-mt", package.cpath)

local Assimp = ffi.load(libpath)


-- A few pointers
local aiStringPtr = ffi.new("struct aiString[1]")
local aiRealPtr = ffi.new("ai_real[1]")
local uintPtr = ffi.new("unsigned int[1]")


-- Logging functionality
local aiLogStream = ffi.new("struct aiLogStream[1]")
aiLogStream[0].callback = function(message, user)
    io.write(ffi.string(message))
end




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

local function readVector3(vec)
    return Vector3(vec.x, vec.y, vec.z)
end




local function importer(data)
    local materials = {}
    local nodes = {}
    local bones = {}
    local animations = {}
    local boneId = 0


    ---@diagnostic disable: param-type-mismatch
    local flags = bit.bor(
        Assimp.aiProcess_CalcTangentSpace,
        Assimp.aiProcess_Triangulate,
        Assimp.aiProcess_SortByPType,
        Assimp.aiProcess_OptimizeMeshes,
        Assimp.aiProcess_FlipUVs
    )
    ---@diagnostic enable: param-type-mismatch


    Assimp.aiAttachLogStream(aiLogStream)
    local aiScene = Assimp.aiImportFileFromMemory(data, #data, flags, nil)

    if aiScene == nil then
        error(ffi.string(Assimp.aiGetErrorString()))
    end

    -- Load materials
    for i=1, aiScene.mNumMaterials do
        local aiMat = aiScene.mMaterials[i-1]
        local name = checkSuccess(Assimp.aiGetMaterialString(aiMat, "?mat.name", 0, 0, aiStringPtr[0])) and readString(aiStringPtr[0]) or ""

        uintPtr[0] = 1

        materials[name] = {
            name         = name,
            tex_diffuse  = checkSuccess(Assimp.aiGetMaterialTexture(aiMat, Assimp.aiTextureType_DIFFUSE,  0, aiStringPtr[0], nil, nil, nil, nil, nil, nil)) and readString(aiStringPtr[0]) or nil,
            tex_specular = checkSuccess(Assimp.aiGetMaterialTexture(aiMat, Assimp.aiTextureType_SPECULAR, 0, aiStringPtr[0], nil, nil, nil, nil, nil, nil)) and readString(aiStringPtr[0]) or nil,
            tex_normals  = checkSuccess(Assimp.aiGetMaterialTexture(aiMat, Assimp.aiTextureType_NORMALS,  0, aiStringPtr[0], nil, nil, nil, nil, nil, nil)) and readString(aiStringPtr[0]) or nil,
            tex_emissive = checkSuccess(Assimp.aiGetMaterialTexture(aiMat, Assimp.aiTextureType_EMISSIVE, 0, aiStringPtr[0], nil, nil, nil, nil, nil, nil)) and readString(aiStringPtr[0]) or nil,
            shininess    = checkSuccess(Assimp.aiGetMaterialFloatArray(aiMat, "$mat.shininess"   , 0, 0, aiRealPtr, uintPtr)) and aiRealPtr[0] or 0,
            opacity      = checkSuccess(Assimp.aiGetMaterialFloatArray(aiMat, "$mat.opacity"     , 0, 0, aiRealPtr, uintPtr)) and aiRealPtr[0] or 0,
            reflectivity = checkSuccess(Assimp.aiGetMaterialFloatArray(aiMat, "$mat.reflectivity", 0, 0, aiRealPtr, uintPtr)) and aiRealPtr[0] or 0,
            refraction   = checkSuccess(Assimp.aiGetMaterialFloatArray(aiMat, "$mat.refracti"    , 0, 0, aiRealPtr, uintPtr)) and aiRealPtr[0] or 0,
        }

    end

    -- Load nodes
    local nodeStack = Stack()
    nodeStack:push(aiScene.mRootNode)

    while nodeStack:peek() do
        local aiNode = nodeStack:pop()
        local node = {
            name = readString(aiNode.mName),
            meshparts = nil,
            children = {},
            transform = readMatrix4x4(aiNode.mTransformation),
        }

        if aiNode.mNumMeshes > 0 then
            local parts = {}
            node.meshparts = parts

            -- Get mesh parts and bones
            for m=1, aiNode.mNumMeshes do
                local aiMesh = aiScene.mMeshes[aiNode.mMeshes[m-1]]
                local part = {
                    name = readString(aiMesh.mName),
                    material = checkSuccess(Assimp.aiGetMaterialString(aiScene.mMaterials[aiMesh.mMaterialIndex], "?mat.name", 0, 0, aiStringPtr[0])) and readString(aiStringPtr[0]) or "",
                    verts = {},
                    indices = {}
                }

                -- Vertices
                for v=1, aiMesh.mNumVertices do
                    local vi = v-1
                    part.verts[v] = {
                        position  = readVector3(aiMesh.mVertices[vi]),
                        normal    = aiMesh.mNormals    ~= nil and readVector3(aiMesh.mNormals[vi])    or Vector3(),
                        tangent   = aiMesh.mTangents   ~= nil and readVector3(aiMesh.mTangents[vi])   or Vector3(),
                        bitangent = aiMesh.mBitangents ~= nil and readVector3(aiMesh.mBitangents[vi]) or Vector3(),
                        uv        = aiMesh.mNumUVComponents[0] > 0 and readVector3(aiMesh.mTextureCoords[0][vi]) or Vector3(),
                        boneIds   = {-1,-1,-1,-1},
                        weights   = {0,0,0,0}
                    }
                end

                -- Indices
                for f=1, aiMesh.mNumFaces do
                    local aiFace = aiMesh.mFaces[f-1]

                    for i=1, aiFace.mNumIndices do
                        part.indices[#part.indices+1] = aiFace.mIndices[i-1]+1
                    end
                end

                -- Bones
                for b=1, aiMesh.mNumBones do
                    local aiBone = aiMesh.mBones[b-1]
                    local boneName = readString(aiBone.mName)
                    local bone = bones[boneName]

                    if not bone then
                        bone = {id = boneId, offset = readMatrix4x4(aiBone.mOffsetMatrix)}
                        boneId = boneId + 1
                        bones[boneName] = bone
                    end

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

                parts[part.name] = part
            end
        end

        nodes[node.name] = node

        -- Load children
        for c=1, aiNode.mNumChildren do
            local aiChildNode = aiNode.mChildren[c-1]

            nodeStack:push(aiChildNode)
            table.insert(node.children, readString(aiChildNode.mName))
        end
    end

    -- Load animations
    for a=1, aiScene.mNumAnimations do
        local aiAnim = aiScene.mAnimations[a-1]
        local animation = {
            name = readString(aiAnim.mName),
            duration = aiAnim.mDuration,
            fps = aiAnim.mTicksPerSecond,
            nodes = {}
        }

        for n=1, aiAnim.mNumChannels do
            local aiNodeAnim = aiAnim.mChannels[n-1]
            local animNode = {
                name = readString(aiNodeAnim.mNodeName),
                positionKeys = {},
                scaleKeys    = {},
                rotationKeys = {},
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

            -- Read missing bones
            if not bones[animNode.name] then
                bones[animNode.name] = {id = boneId, offset = Matrix.Identity()}
                boneId = boneId + 1
            end
        end

        animations[animation.name] = animation
    end

    Assimp.aiReleaseImport(aiScene)
    Assimp.aiDetachLogStream(aiLogStream)


    return {
        nodes = nodes,
        materials = materials,
        bones = bones,
        animations = animations,
    }
end

return importer