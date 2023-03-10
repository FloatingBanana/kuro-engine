local Material = require "src.engine.3DRenderer.materials.material"
local Matrix   = require "engine.math.matrix"
local Vector3  = require "engine.math.vector3"
local FRMaterial = Material:extend()

function FRMaterial:new(mat)
    local attributes = {
        shininess            = {uniform = "u_shininess",      value = 32 --[[mat:shininess()]]},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false)},
        normalMap            = {uniform = "u_normalMap",      value = Material.GetTexture(mat, "normals", 1, true)},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
        viewPosition         = {uniform = "u_viewPosition",   value = Vector3()},
    }

    local frag = lfs.read("engine/shaders/3D/forwardRendering/forwardRendering.frag")

    local shader = lg.newShader(
        "engine/shaders/3D/forwardRendering/forwardRendering.vert",
        Utils.preprocessShader(frag)
    )

    Material.new(self, shader, attributes)
end

return FRMaterial