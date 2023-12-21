local Material = require "engine.3D.materials.baseMaterial"
local Matrix   = require "engine.math.matrix"
local Utils    = require "engine.misc.utils"


--- @class ForwardEmissiveMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field worldMatrix Matrix
--- @field viewProjectionMatrix Matrix
---
--- @overload fun(model: Model, aiMat: unknown): ForwardEmissiveMaterial
local EmissiveMat = Material:extend()

function EmissiveMat:new(model, aiMat)
    local attributes = {
        shininess            = {uniform = "u_strenght",       value = 5},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = model:getTexture(aiMat, "diffuse")},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
    }

    local shader = Utils.newPreProcessedShader("engine/shaders/3D/forwardRendering/emissive.glsl")

    Material.new(self, model, shader, attributes)
end

return EmissiveMat