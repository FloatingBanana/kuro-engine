local Material         = require "src.engine.3DRenderer.materials.material"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local DirectionalLight = require "engine.3DRenderer.lights.directionalLight"
local SpotLight        = require "engine.3DRenderer.lights.spotLight"
local PointLight       = require "engine.3DRenderer.lights.pointLight"
local AmbientLight     = require "engine.3DRenderer.lights.ambientLight"

local fragCode = lfs.read("engine/shaders/3D/forwardRendering/forwardRendering.frag")
local vertCode = Utils.preprocessShader("engine/shaders/3D/forwardRendering/forwardRendering.vert")

local lightShaders = {
    [AmbientLight]     = lg.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_AMBIENT"})),
    [DirectionalLight] = lg.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_DIRECTIONAL"})),
    [SpotLight]        = lg.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_SPOT"})),
    [PointLight]       = lg.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_POINT"})),
}


--- @class ForwardRenderingMaterial: Material
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
--- @field worldMatrix Matrix
--- @field viewProjectionMatrix Matrix
--- @field viewPosition Vector3
---
--- @overload fun(mat: unknown): ForwardRenderingMaterial
local FRMaterial = Material:extend()


function FRMaterial:new(mat)
    local attributes = {
        shininess            = {uniform = "u_shininess",      value = 32 --[[mat:shininess()]]},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = Material.GetTexture(mat, "diffuse", 1, false) or Material.BLANK_TEX},
        normalMap            = {uniform = "u_normalMap",      value = Material.GetTexture(mat, "normals", 1, true) or Material.BLANK_NORMAL},
        worldMatrix          = {uniform = "u_world",          value = Matrix()},
        viewProjectionMatrix = {uniform = "u_viewProj",       value = Matrix()},
        viewPosition         = {uniform = "u_viewPosition",   value = Vector3()},
        boneMatrices         = {uniform = "u_boneMatrices",   value = nil}
    }

    Material.new(self, lightShaders[SpotLight], attributes)
end


--- @param lightClass BaseLight
function FRMaterial:setLightType(lightClass)
    self.shader = lightShaders[lightClass]
end


return FRMaterial