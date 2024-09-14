local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"
local Vector2      = require "engine.math.vector2"
local Utils        = require "engine.misc.utils"

local phongShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/toonMaterialShader.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_FORWARD"})


--- @class ToonMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
---
--- @overload fun(model: Model, aiMat: table): ToonMaterial
local ToonMaterial = Material:extend("ToonMaterial")


function ToonMaterial:new(model, matData)
    local attributes = {
        diffuseTexture     = {uniform = "u_diffuseTexture",     value = Material.DefaultColorTex},
        normalMap          = {uniform = "u_normalMap",          value = Material.DefaultNormalTex},
        transparence       = {uniform = "u_transparence",       value = 1.0 - matData.opacity},
        shininess          = {uniform = "u_shininess",          value = 50},
    }

    Material.new(self, attributes, phongShader)

    if matData.tex_diffuse then
        self:_setupTexturePromise("diffuseTexture", matData.tex_diffuse, model.contentLoader:getImage(matData.tex_diffuse.path, {mipmaps = true}))
    else
        self.diffuseTexture = Utils.newColorImage(Vector2(1), matData.diffusecolor)
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



---@param screenSize Vector2
---@return GBuffer, ShaderEffect
function ToonMaterial.GenerateGBuffer(screenSize)
    local gbuffer = {
        {uniform = "u_GNormal"         , buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rg8"})},
        {uniform = "u_GAlbedoShininess", buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})}
    }

    return gbuffer, phongShader
end


return ToonMaterial