local Material = require "engine.3D.materials.baseMaterial"
local Matrix   = require "engine.math.matrix"
local Utils = require "engine.misc.utils"

local shader = Utils.newPreProcessedShader("engine/shaders/3D/deferred/gbuffer.glsl")


--- @class DeferredMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
---
--- @overload fun(model: Model, aiMat: unknown): DeferredMaterial
local DRMaterial = Material:extend("DeferredMaterial")

function DRMaterial:new(model, aiMat)
    local attributes = {
        shininess              = {uniform = "u_shininess",      value = 1 --[[mat:shininess()]]}, -- hackish way to pass specular value, see engine/shaders/3D/deferred/lightPass.frag
        diffuseTexture         = {uniform = "u_diffuseTexture", value = model:getTexture(aiMat, "diffuse")},
        normalMap              = {uniform = "u_normalMap",      value = model:getTexture(aiMat, "normals")},
    }

    Material.new(self, model, shader, attributes)
end


return DRMaterial