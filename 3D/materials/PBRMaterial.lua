local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"
local Utils        = require "engine.misc.utils"

local function promiseErrorHandler(promise, message)
    print("Failed to load material texture, using a default one. ("..message..")")
end

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
        albedoMap    = {uniform = "u_albedoMap",    value = Material.DefaultColorTex},
        metallicMap  = {uniform = "u_metallicMap",  value = Material.DefaultZeroTex},
        roughnessMap = {uniform = "u_roughnessMap", value = Material.DefaultOneTex},
        normalMap    = {uniform = "u_normalMap",    value = Material.DefaultNormalTex},
    }

    Material.new(self, attributes, pbrShader)


    model.contentLoader:getImage(matData.tex_basecolor or "")
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.albedoMap = promise.content end)

    model.contentLoader:getImage(matData.tex_metalness or "", {linear = true})
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.metallicMap = promise.content end)

    model.contentLoader:getImage(matData.tex_roughness or "", {linear = true})
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.roughnessMap = promise.content end)

    model.contentLoader:getImage(matData.tex_normals or "", {linear = true})
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.normalMap = promise.content end)
end


---@param screenSize Vector2
---@return GBuffer, ShaderEffect
function PBRMaterial.GenerateGBuffer(screenSize)
    local gbuffer = {
        {uniform = "u_GNormalMetallicRoughness", buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})},
        {uniform = "u_GAlbedoAO"               , buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})}
    }

    return gbuffer, pbrShader
end


return PBRMaterial