local Material = require "engine.3DRenderer.materials.baseMaterial"
local Matrix   = require "engine.math.matrix"

local shader = Utils.newPreProcessedShader("engine/shaders/3D/deferred/gbuffer.glsl")


--- @class DeferredMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
--- @field worldMatrix Matrix
--- @field viewProjectionMatrix Matrix
--- @field previousTransformation Matrix
---
--- @overload fun(mat: unknown): DeferredMaterial
local DRMaterial = Material:extend()

function DRMaterial:new(mat)
    local attributes = {
        shininess              = {uniform = "u_shininess",      value = 1 --[[mat:shininess()]]}, -- hackish way to pass specular value, see engine/shaders/3D/deferred/lightPass.frag
        diffuseTexture         = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false) or Material.BLANK_TEX},
        normalMap              = {uniform = "u_normalMap",      value = Material.GetTexture(mat, "normals", 1, true) or Material.BLANK_NORMAL},
        worldMatrix            = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix   = {uniform = "u_viewProj",       value = Matrix()},
        previousTransformation = {uniform = "u_prevTransform",  value = Matrix()},
        boneMatrices           = {uniform = "u_boneMatrices",   value = nil}
    }

    Material.new(self, shader, attributes)
end


return DRMaterial