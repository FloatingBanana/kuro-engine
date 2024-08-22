local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"
local Utils        = require "engine.misc.utils"
local Vector2      = require "engine.math.vector2"


local pbrShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/PBRMaterialShader.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_FORWARD"})

--- @class PBRMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
---
--- @overload fun(model: Model, aiMat: table): PBRMaterial
local PBRMaterial = Material:extend("PBRMaterial")

function PBRMaterial:new(model, matData)
    local attributes = {
        albedoMap            = {uniform = "u_albedoMap",            value = Material.DefaultColorTex},
        emissiveMap          = {uniform = "u_emissiveMap",          value = Material.DefaultZeroTex},
        metallicRoughnessMap = {uniform = "u_metallicRoughnessMap", value = Material.DefaultOneTex},
        normalMap            = {uniform = "u_normalMap",            value = Material.DefaultNormalTex},
        emissiveIntensity    = {uniform = "u_emissiveIntensity",    value = matData.emissive_intensity},
        transparence         = {uniform = "u_transparence",         value = 1.0 - matData.opacity},
    }

    Material.new(self, attributes, pbrShader)


    if matData.tex_basecolor then
        self:_setupTexturePromise("albedoMap", matData.tex_basecolor, model.contentLoader:getImage(matData.tex_basecolor.path, {mipmaps = true}))
    else
        self.albedoMap = Utils.newColorImage(Vector2(1), matData.basecolor)
    end

    if matData.tex_emissive then
        self:_setupTexturePromise("emissiveMap", matData.tex_emissive, model.contentLoader:getImage(matData.tex_emissive.path, {mipmaps = true}))
    else
        self.emissiveMap = Utils.newColorImage(Vector2(1), matData.emissivecolor)
    end

    if matData.tex_metallicroughness then
        self:_setupTexturePromise("metallicRoughnessMap", matData.tex_metallicroughness, model.contentLoader:getImage(matData.tex_metallicroughness.path, {mipmaps = true, linear = true}))
    else
        self.metallicRoughnessMap = Utils.newColorImage(Vector2(1), {matData.metallic, matData.roughness, 0, 0})
    end

    if matData.tex_normals then
        self:_setupTexturePromise("normalMap", matData.tex_normals, model.contentLoader:getImage(matData.tex_normals.path, {mipmaps = true, linear = true}))
    end
end


---@private
---@param field string
---@param texData table
---@param promise ContentPromise
function PBRMaterial:_setupTexturePromise(field, texData, promise)
    promise.onCompleteEvent:addCallback(function(event, promise)
        self[field] = promise.content
        promise.content:setWrap(texData.mapMode_h, texData.mapMode_v)
        promise.content:setMipmapFilter("linear", 0)
    end)

    promise:setErrorHandler(function(promise, message)
        print("Failed to load material texture "..field..", using a default one. ("..message..")")
    end)
end


---@param screenSize Vector2
---@return GBuffer, ShaderEffect
function PBRMaterial.GenerateGBuffer(screenSize)
    local gbuffer = {
        {uniform = "u_GNormalMetallicRoughness", buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})},
        {uniform = "u_GAlbedoAO"               , buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})},
        {uniform = "u_GEmissive"               , buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rg11b10f"})},
    }

    return gbuffer, pbrShader
end


return PBRMaterial