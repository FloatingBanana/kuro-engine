local Material = require "src.engine.3DRenderer.materials.material"
local Matrix   = require "engine.math.matrix"
local Vector3  = require "engine.math.vector3"
local FRMaterial = Material:extend()

function FRMaterial:new(mat)
    local attributes = {
        shininess            = {uniform = "u_shininess",      value = 1 --[[mat:shininess()]]}, -- hackish way to pass specular value, see engine/shaders/3D/deferred/lightPass.frag
        diffuseTexture       = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false)},
        normalMap            = {uniform = "u_normalMap",      value = Material.GetTexture(mat, "normals", 1, true)},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
    }

    local shader = lg.newShader("engine/shaders/3D/deferred/gbuffer.glsl")

    Material.new(self, shader, attributes)
end

return FRMaterial