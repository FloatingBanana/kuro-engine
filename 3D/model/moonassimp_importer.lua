local Assimp     = require "moonassimp"
local Matrix     = require "engine.math.matrix"
local Stack      = require "engine.collections.stack"
local Vector3    = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local Lume       = require "engine.3rdparty.lume"

--[[
data = {
    materials = {
        [name] = {
            name         = <string>,
            tex_diffuse  = <string>,
            tex_specular = <string>,
            tex_normals  = <string>,
            tex_emissive = <string>,
            shininess    = <number>,
            opacity      = <number>,
            reflectivity = <number>,
            refraction   = <number>
        }
        ...
    },

    nodes = {
        [name] = {
            name = <string>,
            transform = <Matrix>,
            children = <string[]>,
            meshparts = nil | {
                [name] = {
                    material = <string>,
                    indices = <number[]>
                    verts = {
                        {
                            position  = <Vector3>,
                            normal    = <Vector3>,
                            tangent   = <Vector3>,
                            bitangent = <Vector3>,
                            uv        = <Vector3>,
                            boneIds   = <number[4]>,
                            weights   = <number[4]>
                        }
                        ...
                    }
                }
                ...
            }
        }
        ...
    },

    bones = {
        [name] = {
            id = <number>,
            offset = <Matrix>
        },
        ...
    },

    animations = {
        [name] = {
            names = <string>,
            duration = <number>,
            fps      = <number>,
            nodes = {
                {
                    name = <string>,
                    positionKeys = {time = <number>, value = <Vector3>}[]
                    scaleKeys    = {time = <number>, value = <Vector3>}[]
                    rotationKeys = {time = <number>, value = <Quaternion>}[]
                }
                ...
            }
        },
        ...
    }
}
]]

local function importer(data)
    local materials = {}
    local nodes = {}
    local bones = {}
    local animations = {}
    local boneId = 0

    local aiModel, err = Assimp.import_file_from_memory(data, unpack({"calc tangent space", "triangulate", "sort by p type", "optimize meshes", "flip uvs"}))
    assert(aiModel, err)

    -- Load materials
    for i, aiMat in ipairs(aiModel:materials()) do
        materials[aiMat:name()] = {
            name         = aiMat:name(),
            tex_diffuse  = aiMat:texture_path("diffuse", 1),
            tex_specular = aiMat:texture_path("specular", 1),
            tex_normals  = aiMat:texture_path("normals", 1),
            tex_emissive = aiMat:texture_path("emissive", 1),
            shininess    = aiMat:shininess(),
            opacity      = aiMat:opacity(),
            reflectivity = aiMat:reflectivity(),
            refraction   = aiMat:refraction(),
        }
    end


    -- Load nodes
    local nodeStack = Stack()
    nodeStack:push(aiModel:root_node())

    while nodeStack:peek() do
        local aiNode = nodeStack:pop()
        local node = {
            name = aiNode:name(),
            transform = Matrix(aiNode:transformation()):transpose(),
            meshparts = nil,
            children = {}
        }

        if aiNode:num_meshes() > 0 then
            local parts = {}
            node.meshparts = parts

            -- Get mesh parts and bones
            for _, aiMesh in pairs(aiNode:meshes()) do
                local part = {
                    name = aiMesh:name(),
                    material = aiMesh:material():name(),
                    verts = {},
                    indices = {}
                }

                -- Vertices
                for vi=1, aiMesh:num_vertices() do
                    part.verts[vi] = {
                        position  = Vector3(aiMesh:position(vi)),
                        normal    = Vector3(aiMesh:normal(vi)),
                        tangent   = Vector3(aiMesh:tangent(vi)),
                        bitangent = Vector3(aiMesh:bitangent(vi)),
                        uv        = aiMesh:has_texture_coords(1) and Vector3(aiMesh:texture_coords(1, vi)) or Vector3(),
                        boneIds   = {-1,-1,-1,-1},
                        weights   = {0,0,0,0}
                    }
                end

                -- Indices
                for i=1, aiMesh:num_faces() do
                    Lume.push(part.indices, aiMesh:face(i):indices())
                end

                -- Bones
                for j=1, aiMesh:num_bones() do
                    local aiBone = aiMesh:bone(j)
                    local bone = bones[aiBone:name()]

                    if not bone then
                        bone = {
                            offset = Matrix(aiBone:offset_matrix()):transpose(),
                            id = boneId
                        }
                        boneId = boneId + 1
                        bones[aiBone:name()] = bone
                    end

                    for bv, weight in pairs(aiBone:weights() or {}) do
                        for i=1, 4 do
                            if part.verts[bv].boneIds[i] == -1 then
                                part.verts[bv].boneIds[i] = bone.id
                                part.verts[bv].weights[i] = weight
                                break
                            end
                        end
                    end
                end

                parts[aiMesh:name()] = part
            end
        end

        nodes[aiNode:name()] = node

        -- Load children
        for i, aiChild in ipairs(aiNode:children()) do
            nodeStack:push(aiChild)
            table.insert(node.children, aiChild:name())
        end
    end

    -- Load animations
    for i, aiAnim in ipairs(aiModel:animations()) do
        local animation = {
            name = aiAnim:name(),
            duration = aiAnim:duration(),
            fps = aiAnim:ticks_per_second(),
            nodes = {}
        }

        for j, aiAnimNode in ipairs(aiAnim:node_anims()) do
            local nodeName = aiAnimNode:node_name()
            local animNode = {
                name = nodeName,
                positionKeys = {},
                scaleKeys    = {},
                rotationKeys = {},
            }

            for k, key in ipairs(aiAnimNode:position_keys()) do
                animNode.positionKeys[k] = {time = key.time, value = Vector3(unpack(key.value))}
            end

            for k, key in ipairs(aiAnimNode:rotation_keys()) do
                -- for some fucking stupid reason moonassimp quaternion values are in the order of {w, x, y, z} (i'm tired boss)
                animNode.rotationKeys[k] = {time = key.time, value = Quaternion(key.value[2], key.value[3], key.value[4], key.value[1])}
            end

            for k, key in ipairs(aiAnimNode:scaling_keys()) do
                animNode.scaleKeys[k] = {time = key.time, value = Vector3(unpack(key.value))}
            end

            animation.nodes[nodeName] = animNode

            -- Read missing bones
            if not bones[nodeName] then
                bones[nodeName] = {id = #bones, offset = Matrix.Identity()}
                boneId = boneId + 1
            end
        end

        animations[aiAnim:name()] = animation
    end


    return {
        nodes = nodes,
        materials = materials,
        bones = bones,
        animations = animations,
    }
end

return importer