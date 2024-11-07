local Meshpart       = require "engine.3D.model.meshpart"
local ModelNode      = require "engine.3D.model.modelNode"
local MeshNode       = require "engine.3D.model.modelMesh"
local CameraNode     = require "engine.3D.model.modelCamera"
local LightNode      = require "engine.3D.model.modelLight"
local ArmatureNode   = require "engine.3D.model.modelArmature"
local BoneNode       = require "engine.3D.model.modelBone"
local ModelAnimation = require "engine.3D.model.animation.modelAnimation"
local ContentLoader  = require "engine.resourceHandling.contentLoader"
local Object         = require "engine.3rdparty.classic.classic"


--- @alias ModelLoadingOptions {materials: table<string, BaseMaterial>, contentLoader: ContentLoader, triangulate: boolean, flipUVs: boolean, removeUnusedMaterials: boolean, optimizeGraph: boolean}
--- @alias BoneInfo {id: integer, offset: Matrix4}

--- @class Model: Object
---
--- @field nodes table<string, ModelNode>
--- @field meshes table<string, ModelMesh>
--- @field meshParts MeshPart[]
--- @field lights table<string, ModelLight>
--- @field cameras table<string, ModelCamera>
--- @field materials table<string, BaseMaterial>
--- @field animations table<string, ModelAnimation>
--- @field armatures table<string, ModelArmature>
--- @field contentLoader ContentLoader
--- @field opts ModelLoadingOptions
---
--- @overload fun(file: string, opts: ModelLoadingOptions): Model
local Model = Object:extend("Model")


function Model:new(file, opts)
    self.nodes = {}
    self.meshes = {}
    self.meshParts = {}
    self.cameras = {}
    self.lights = {}
    self.materials = {}
    self.animations = {}
    self.armatures = {}
    self.contentLoader = opts.contentLoader or ContentLoader()
    self.opts = opts


    -- Read model data
    local importer = require "engine.3D.model.assimp_importer"
    local modelData = importer(file, opts.triangulate, opts.flipUVs, opts.removeUnusedMaterials, opts.optimizeGraph)


    -- Load materials
    if opts.materials then
        for name, matData in pairs(modelData.materials) do
            local mat = opts.materials[name] or opts.materials.default:clone() ---@type BaseMaterial
            assert(mat, "Material for '"..name.."' not defined")

            mat:loadMaterialData(matData, self)
            self.materials[name] = mat
        end
    end

    self.contentLoader:loadAllAsync()

    -- Get mesh parts
    for p, partData in pairs(modelData.meshParts) do
        self.meshParts[p] = Meshpart(partData, self)
    end

    -- Start loading from root node
    self.rootNode = self:__loadNode(modelData.rootNode, modelData)

    -- Load animations
    for name, animData in pairs(modelData.animations) do
        self.animations[name] = ModelAnimation(self, animData)
    end
end



--- @private
--- @param nodeData table
--- @param modelData table
--- @return ModelNode
function Model:__loadNode(nodeData, modelData)
    local node = nil
    local nodeName = nodeData.name
    local nodeTransform = nodeData.transform

    if nodeData.meshParts then
        local parts = {}

        for p, pIndex in ipairs(nodeData.meshParts) do
            parts[p] = self.meshParts[pIndex]
        end

        -- Mesh node
        node = MeshNode(self, nodeName, nodeTransform, parts)
        self.meshes[nodeName] = node

    elseif modelData.cameras[nodeName] then
        -- Camera node
        node = CameraNode(self, nodeName, nodeTransform, modelData.cameras[nodeName])
        self.cameras[nodeName] = node

    elseif modelData.lights[nodeName] then
        -- Light node
        node = LightNode(self, nodeName, nodeTransform, modelData.lights[nodeName])
        self.lights[nodeName] = node

    elseif modelData.armatures[nodeName] then
        -- Armature node
        node = ArmatureNode(self, nodeName, nodeTransform)
        self.armatures[nodeName] = node
    else
        -- Empty node
        node = ModelNode(self, nodeName, nodeTransform)
    end

    self.nodes[nodeName] = node

    -- Load children
    for c, childNode in ipairs(nodeData.children) do
        local armatureData = modelData.armatures[nodeName]

        if armatureData and armatureData[childNode.name] then
            local bone = self:__loadBone(childNode, modelData, node)
            node.rootBones[childNode.name] = bone
        else
            local child = self:__loadNode(childNode, modelData, nil)
            node:addChild(child)
        end
    end

    return node
end


---@private
--- @param nodeData table
--- @param modelData table
--- @param armatureNode ModelArmature
--- @return ModelBone
function Model:__loadBone(nodeData, modelData, armatureNode)
    local boneData = modelData.armatures[armatureNode.name][nodeData.name]
    local bone = BoneNode(self, nodeData.name, nodeData.transform, boneData.offset, boneData.id)

    armatureNode.bones[nodeData.name] = bone

    for c, childNode in ipairs(nodeData.children) do
        local child = self:__loadBone(childNode, modelData, armatureNode)
        bone:addChild(child)
    end

    return bone
end


return Model