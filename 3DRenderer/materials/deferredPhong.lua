local Material = require "src.engine.3DRenderer.materials.material"
local Matrix   = require "engine.math.matrix"

local shader = lg.newShader("engine/shaders/3D/deferred/gbuffer.glsl")


--- @class DeferredRenderingMaterial: Material
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
--- @field worldMatrix Matrix
--- @field viewProjectionMatrix Matrix
---
--- @overload fun(mat: unknown): DeferredRenderingMaterial
local DRMaterial = Material:extend()

function DRMaterial:new(mat)
    local attributes = {
        shininess            = {uniform = "u_shininess",      value = 1 --[[mat:shininess()]]}, -- hackish way to pass specular value, see engine/shaders/3D/deferred/lightPass.frag
        diffuseTexture       = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false)},
        normalMap            = {uniform = "u_normalMap",      value = Material.GetTexture(mat, "normals", 1, true)},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
    }

    Material.new(self, shader, attributes)
end


return DRMaterial