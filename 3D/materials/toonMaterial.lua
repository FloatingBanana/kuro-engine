local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"
local Vector2      = require "engine.math.vector2"
local Utils        = require "engine.misc.utils"

local phongShader = ShaderEffect("engine/shaders/3D/toonMaterialShader.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_FORWARD"})


--- @class ToonMaterial: BaseMaterial
---
--- @field diffuseMap love.Texture
--- @field normalMap love.Texture
--- @field shininess number
--- @field transparency number
---
--- @overload fun(): ToonMaterial
local ToonMaterial = Material:extend("ToonMaterial")


function ToonMaterial:new()
    local attributes = {
        diffuseMap   = {uniform = "u_input.diffuseMap",   value = Material.DefaultColorTex},
        normalMap    = {uniform = "u_input.normalMap",    value = Material.DefaultNormalTex},
        shininess    = {uniform = "u_input.shininess",    value = 128},
        transparency = {uniform = "u_input.transparency", value = 0},

        ssaoTexture  = {uniform = "u_input.ssaoTexture",  value = Material.DefaultOneTex},
    }

    Material.new(self, attributes, phongShader)
end


---@param matData table
---@param model Model
function ToonMaterial:loadMaterialData(matData, model)
    -- self.shininess = matData.shininess
    self.transparency = 1.0 - matData.opacity

    if matData.tex_diffuse then
        self:_setupTexturePromise("diffuseMap", matData.tex_diffuse, model.contentLoader:getImage(matData.tex_diffuse.path, {mipmaps = true}))
    else
        self.diffuseMap = Utils.newColorImage(Vector2(1), matData.diffusecolor)
    end

    if matData.tex_normals then
        self:_setupTexturePromise("normalMap", matData.tex_normals, model.contentLoader:getImage(matData.tex_normals.path, {mipmaps = true, linear = true}))
    end
end


---@private
---@param field string
---@param texData table
---@param promise ContentPromise
function ToonMaterial:_setupTexturePromise(field, texData, promise)
    promise.onCompleteEvent:addCallback(function(event, promise)
        self[field] = promise.content
        promise.content:setWrap(texData.mapMode_h, texData.mapMode_v)
        promise.content:setMipmapFilter("linear", 1)
    end)

    promise:setErrorHandler(function(promise, message)
        print("Failed to load material texture "..field..", using a default one. ("..message..")")
    end)
end


---@type love.PixelFormat[]
ToonMaterial.GBufferLayout = {"rgba16", "rgba8"}


return ToonMaterial