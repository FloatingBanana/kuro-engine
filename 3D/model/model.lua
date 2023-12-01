local Assimp         = require "moonassimp"
local Matrix         = require "engine.math.matrix"
local Mesh           = require "engine.3D.model.modelMesh"
local Meshpart       = require "engine.3D.model.meshpart"
local ModelNode      = require "engine.3D.model.modelNode"
local ModelAnimation = require "engine.3D.model.animation.modelAnimation"
local Object         = require "engine.3rdparty.classic.classic"


-- Default textures
local texData = love.data.decode("data", "base64", "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAQSURBVBhXY/gPhBDwn+E/ABvyA/1Bas9NAAAAAElFTkSuQmCC")
local normalData = love.data.decode("data", "base64", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsIAAA7CARUoSoAAAAANSURBVBhXY2ho+P8fAAaCAv+ce/dzAAAAAElFTkSuQmCC")

local blankTex = love.graphics.newImage(texData, {linear = true})
local blankNormal = love.graphics.newImage(normalData, {linear = true})
blankTex:setWrap("repeat")
blankTex:setFilter("nearest", "nearest")


local textureDefaults = {diffuse = blankTex, normal = blankNormal}
local textureTypes = {"diffuse", "normals"}
local linearTexTypes = {normals = true}


--- @alias ModelLoadingOptions {materials: table<string, BaseMaterial>}
--- @alias BoneInfo {id: integer, offset: Matrix}

--- @class Model: Object
---
--- @field nodes table<string, ModelNode>
--- @field meshes table<string, ModelMesh>
--- @field materials table<string, BaseMaterial>
--- @field animations table<string, ModelAnimation>
--- @field boneInfos table<string, BoneInfo>
--- @field textures table<string, love.Texture>
--- @field opts ModelLoadingOptions
--- @field private _boneCount integer
---
--- @overload fun(file: string, opts: ModelLoadingOptions): Model
local Model = Object:extend()


function Model:new(file, opts)
    self.nodes = {}
    self.meshes = {}
    self.materials = {}
    self.animations = {}
    self.boneInfos = {}
    self.textures = {}
    self.opts = opts
    self._boneCount = 0

    -- Read model data
    local data = love.filesystem.read("string", file)
    local aiModel, err = Assimp.import_file_from_memory(data, unpack(opts.flags or {"none"}))

    assert(aiModel, err)

    -- Load materials
    if opts.materials then
        for i, aiMat in ipairs(aiModel:materials()) do
            local name = aiMat:name()
            local matClass = opts.materials[name] or opts.materials.default

            assert(matClass, "Material class for '"..name.."' not defined")

            -- Load textures
            for j, textype in ipairs(textureTypes) do
                local texpath = aiMat:texture_path(textype, 1)

                if texpath and not self.textures[texpath] then
                    local fullpath = file:match("^.*/")..texpath
                    self.textures[texpath] = love.graphics.newImage(fullpath, {linear = linearTexTypes[textype]})
                end
            end


            self.materials[name] = matClass(self, aiMat)
        end
    end

    -- Start loading from root node
    local root = aiModel:root_node()
    self.rootNode = self:__loadNode(root, aiModel)

    -- Load animations
    for i, aiAnim in ipairs(aiModel:animations()) do
        self.animations[aiAnim:name()] = ModelAnimation(self, aiAnim)
    end
end


---@param aiMat unknown
---@param type "diffuse"|"normals"
function Model:getTexture(aiMat, type)
    local path = aiMat:texture_path(type, 1)

    if path and self.textures[path] then
        return self.textures[path]
    end

    print(("%s: No texture of type '%s' at path %s, using a default one."):format(aiMat:name(), type, path or "<no path>"))
    return textureDefaults[type] or blankTex
end


---@param name string
---@param offset Matrix
function Model:addBone(name, offset)
    self.boneInfos[name] = {id = self._boneCount, offset = offset}
    self._boneCount = self._boneCount + 1
end


--- @private
--- @param aiNode unknown
--- @param aiModel unknown
function Model:__loadNode(aiNode, aiModel)
    local transform = Matrix(aiNode:transformation()):transpose()
    local name = aiNode:name()
    local node = nil

    if aiNode:num_meshes() > 0 then
        local parts = {}

        -- Get mesh parts and bones
        for i, aiMesh in pairs(aiNode:meshes()) do
            for j=1, aiMesh:num_bones() do
                local aiBone = aiMesh:bone(j)
                local boneName = aiBone:name()

                if not self.boneInfos[boneName] then
                    local boneOffset = Matrix(aiBone:offset_matrix()):transpose() -- convert to column major
                    self:addBone(boneName, boneOffset)
                end
            end

            parts[i] = Meshpart(aiMesh, self)
        end

        -- Create mesh
        node = Mesh(self, name, transform, parts)
        self.meshes[name] = node
    else
        -- empty node
        node = ModelNode(self, name, transform)
    end

    self.nodes[name] = node

    -- Load children
    for i, aiChild in ipairs(aiNode:children()) do
        local child = self:__loadNode(aiChild, aiModel)

        node:addChild(child)
    end

    return node
end


return Model