local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"
local Utils        = require "engine.misc.utils"
local Vector2      = require "engine.math.vector2"
local Matrix4      = require "engine.math.matrix4"
local Vector3      = require "engine.math.vector3"
local CubemapUtils = require "engine.misc.cubemapUtils"


local pbrShader = ShaderEffect("engine/shaders/3D/PBRMaterialShader.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_FORWARD"})
local brdfLUT = CubemapUtils.getBRDF_LUT(512)

--- @class PBRMaterial: BaseMaterial
---
--- @field albedoMap love.Texture
--- @field emissiveMap love.Texture
--- @field metallicRoughnessMap love.Texture
--- @field normalMap love.Texture
--- @field anisotropy number
--- @field emissiveIntensity number
--- @field transparency number
---
--- @field reflectionProbeTexture love.Texture
--- @field reflectionProbeInvTransform Matrix4
--- @field reflectionProbePosition Vector3
---
--- @field irradianceVolumeProbeBuffer love.Texture
--- @field irradianceVolumeInvTransform Matrix4
--- @field irradianceVolumeGridSize Vector3
---
--- @field ssaoTexture love.Texture
--- @field brdfLUT love.Texture
---
--- @overload fun(): PBRMaterial
local PBRMaterial = Material:extend("PBRMaterial")

function PBRMaterial:new()
    local attributes = {
        albedoMap            = {uniform = "u_input.albedoMap",            value = Material.DefaultColorTex},
        emissiveMap          = {uniform = "u_input.emissiveMap",          value = Material.DefaultZeroTex},
        metallicRoughnessMap = {uniform = "u_input.metallicRoughnessMap", value = Material.DefaultOneTex},
        normalMap            = {uniform = "u_input.normalMap",            value = Material.DefaultNormalTex},
        anisotropy           = {uniform = "u_input.anisotropy",           value = 0},
        emissiveIntensity    = {uniform = "u_input.emissiveIntensity",    value = 0},
        transparency         = {uniform = "u_input.transparency",         value = 0},

        -- Ambient
        reflectionProbeTexture       = {uniform = "u_input.reflectionProbe.texture",        value = Material.DefaultZeroCubeTex},
        reflectionProbeInvTransform  = {uniform = "u_input.reflectionProbe.invTransform",   value = Matrix4.Identity()},
        reflectionProbePosition      = {uniform = "u_input.reflectionProbe.position",       value = Vector3(0,0,0)},

        irradianceVolumeProbeBuffer  = {uniform = "u_input.irradianceVolume.probeBuffer",   value = Material.DefaultZeroTex},
        irradianceVolumeInvTransform = {uniform = "u_input.irradianceVolume.invTransform",  value = Matrix4.Identity()},
        irradianceVolumeGridSize     = {uniform = "u_input.irradianceVolume.gridSize",      value = Vector3(0,0,0)},

        ssaoTexture                  = {uniform = "u_input.ssaoTexture",                    value = Material.DefaultOneTex},
        brdfLUT                      = {uniform = "u_input.brdfLUT",                        value = brdfLUT},
    }

    Material.new(self, attributes, pbrShader)
end


---@param matData table
---@param model Model
function PBRMaterial:loadMaterialData(matData, model)
    self.emissiveIntensity = matData.emissive_intensity
    self.transparency = 1.0 - matData.opacity

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
        self.metallicRoughnessMap = Utils.newColorImage(Vector2(1), {0, matData.roughness, matData.metallic, 0})
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


---@type love.PixelFormat[]
PBRMaterial.GBufferLayout = {"rgba16", "rgba8", "rg11b10f", "rg11b10f"}


return PBRMaterial