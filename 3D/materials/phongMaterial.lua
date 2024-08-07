local Material     = require "engine.3D.materials.baseMaterial"
local ShaderEffect = require "engine.misc.shaderEffect"

local function promiseErrorHandler(promise, message)
    print("Failed to load material texture, using a default one. ("..message..")")
end

local phongShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/phongMaterialShader.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_FORWARD"})


--- @class PhongMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
---
--- @overload fun(model: Model, aiMat: table): PhongMaterial
local PhongMaterial = Material:extend("PhongMaterial")


function PhongMaterial:new(model, matData)
    local attributes = {
        shininess      = {uniform = "u_shininess",      value = 128 --[[matData.shininess]]},
        diffuseTexture = {uniform = "u_diffuseTexture", value = Material.DefaultColorTex},
        normalMap      = {uniform = "u_normalMap",      value = Material.DefaultNormalTex},
        transparence   = {uniform = "u_transparence",   value = 0},
    }

    Material.new(self, attributes, phongShader)

    model.contentLoader:getImage(matData.tex_diffuse or "")
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.diffuseTexture = promise.content end)

    model.contentLoader:getImage(matData.tex_normals or "", {linear = true})
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.normalMap = promise.content end)
end



---@param screenSize Vector2
---@return GBuffer, ShaderEffect
function PhongMaterial.GenerateGBuffer(screenSize)
    local gbuffer = {
        {uniform = "u_GNormal"        , buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rg8"})},
        {uniform = "u_GAlbedoSpecular", buffer = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})}
    }

    return gbuffer, phongShader
end


return PhongMaterial