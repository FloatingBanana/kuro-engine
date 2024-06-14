local Material         = require "engine.3D.materials.baseMaterial"

local function promiseErrorHandler(promise, message)
    print("Failed to load material texture, using a default one. ("..message..")")
end


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
    }

    Material.new(self, attributes)

    model.contentLoader:getImage(matData.tex_diffuse or "")
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.diffuseTexture = promise.content end)

    model.contentLoader:getImage(matData.tex_normals or "", {linear = true})
        :setErrorHandler(promiseErrorHandler)
        .onCompleteEvent:addCallback(function(event, promise) self.normalMap = promise.content end)
end


return PhongMaterial