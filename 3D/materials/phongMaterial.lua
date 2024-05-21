local Material         = require "engine.3D.materials.baseMaterial"


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
        shininess            = {uniform = "u_shininess",      value = 32 --[[mat:shininess()]]},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = model:getTexture(matData, "diffuse")},
        normalMap            = {uniform = "u_normalMap",      value = model:getTexture(matData, "normals")},
    }

    Material.new(self, attributes)
end


return PhongMaterial