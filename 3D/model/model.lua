local Mesh           = require "engine.3D.model.modelMesh"
local Meshpart       = require "engine.3D.model.meshpart"
local ModelNode      = require "engine.3D.model.modelNode"
local ModelAnimation = require "engine.3D.model.animation.modelAnimation"
local ContentLoader  = require "engine.resourceHandling.contentLoader"
local Object         = require "engine.3rdparty.classic.classic"


--- @alias ModelLoadingOptions {materials: table<string, BaseMaterial>, contentLoader: ContentLoader, triangulate: boolean, flipUVs: boolean, removeUnusedMaterials: boolean, optimizeGraph: boolean}
--- @alias BoneInfo {id: integer, offset: Matrix}

--- @class Model: Object
---
--- @field nodes table<string, ModelNode>
--- @field meshes table<string, ModelMesh>
--- @field meshParts table<string, MeshPart>
--- @field materials table<string, BaseMaterial>
--- @field animations table<string, ModelAnimation>
--- @field boneInfos table<string, BoneInfo>
--- @field contentLoader ContentLoader
--- @field opts ModelLoadingOptions
---
--- @overload fun(file: string, opts: ModelLoadingOptions): Model
local Model = Object:extend("Model")


function Model:new(file, opts)
    self.nodes = {}
    self.meshes = {}
    self.meshParts = {}
    self.materials = {}
    self.animations = {}
    self.boneInfos = {}
    self.contentLoader = opts.contentLoader or ContentLoader()
    self.opts = opts


    -- Read model data
    local importer = require "engine.3D.model.assimp_importer"
    local modelData = importer(file, opts.triangulate, opts.flipUVs, opts.removeUnusedMaterials, opts.optimizeGraph)


    -- Load materials
    if opts.materials then
        for name, matData in pairs(modelData.materials) do
            local matClass = opts.materials[name] or opts.materials.default

            assert(matClass, "Material class for '"..name.."' not defined")
            self.materials[name] = matClass(self, matData)
        end
    end

    self.contentLoader:loadAllAsync()

    -- Bones
    self.boneInfos = modelData.bones

    -- Get mesh parts
    for name, partData in pairs(modelData.meshParts) do
        self.meshParts[name] = Meshpart(partData, self)
    end

    -- Start loading from root node
    local root = modelData.nodes.RootNode
    self.rootNode = self:__loadNode(root, modelData)

    -- Load animations
    for name, animData in pairs(modelData.animations) do
        self.animations[name] = ModelAnimation(self, animData)
    end
end



--- @private
--- @param nodeData table
--- @param modelData table
function Model:__loadNode(nodeData, modelData)
    local node = nil

    if nodeData.meshParts then
        local parts = {}

        for i, partname in ipairs(nodeData.meshParts) do
            parts[#parts+1] = self.meshParts[partname]
        end

        -- Create mesh
        node = Mesh(self, nodeData.name, nodeData.transform, parts)
        self.meshes[nodeData.name] = node
    else
        -- empty node
        node = ModelNode(self, nodeData.name, nodeData.transform)
    end

    self.nodes[nodeData.name] = node

    -- Load children
    for i, childname in ipairs(nodeData.children) do
        local child = self:__loadNode(modelData.nodes[childname], modelData)
        node:addChild(child)
    end

    return node
end


return Model