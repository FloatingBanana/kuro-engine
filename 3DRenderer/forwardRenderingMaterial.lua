local Material = require "engine.3DRenderer.material"
local Matrix   = require "engine.math.matrix"
local Vector3  = require "engine.math.vector3"
local FRMaterial = Material:extend()

local textures = {}

local function getTexture(mat, type, texIndex, linear)
    local path = mat:texture_path(type, texIndex)

    if path then
        if not textures[path] then
            textures[path] = lg.newImage("assets/models/"..path, {linear = linear})
        end

        return textures[path]
    else
        return nil
    end
end

function FRMaterial:new(mat)
    local attributes = {
        specularColor        = {uniform = "u_specularColor",  value = {1,1,1}},
        shininess            = {uniform = "u_shininess",      value = mat:shininess()},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = getTexture(mat, "diffuse", 1, false)},
        normalMap            = {uniform = "u_normalMap",      value = getTexture(mat, "normals", 1, true)},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
        viewPosition         = {uniform = "u_viewPosition",   value = Vector3()},
    }

    local frag = lfs.read("engine/shaders/3D/forwardRendering/forwardRendering.frag")
    local preProcessedFrag = Utils.preprocessShader(frag)

    local shader = lg.newShader(
        "engine/shaders/3D/forwardRendering/forwardRendering.vert",
        preProcessedFrag
    )

    Material.new(self, shader, attributes)
end

return FRMaterial