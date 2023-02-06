local Material = require "src.engine.3DRenderer.materials.material"
local Matrix   = require "engine.math.matrix"
local Vector3  = require "engine.math.vector3"
local EmissiveMat = Material:extend()

function EmissiveMat:new(mat)
    local attributes = {
        shininess            = {uniform = "u_strenght",       value = 5},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false)},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
    }

    local shader = lg.newShader("engine/shaders/3D/forwardRendering/emissive.glsl")

    Material.new(self, shader, attributes)
end

return EmissiveMat