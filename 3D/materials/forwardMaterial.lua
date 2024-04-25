local Material         = require "engine.3D.materials.baseMaterial"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local DirectionalLight = require "engine.3D.lights.directionalLight"
local SpotLight        = require "engine.3D.lights.spotLight"
local PointLight       = require "engine.3D.lights.pointLight"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local Utils            = require "engine.misc.utils"

local fragCode = love.filesystem.read("engine/shaders/3D/forwardRendering/forwardRendering.frag")
local vertCode = Utils.preprocessShader("engine/shaders/3D/forwardRendering/forwardRendering.vert")

local lightShaders = {
    [AmbientLight]     = love.graphics.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_AMBIENT"})),
    [DirectionalLight] = love.graphics.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_DIRECTIONAL"})),
    [SpotLight]        = love.graphics.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_SPOT"})),
    [PointLight]       = love.graphics.newShader(vertCode, Utils.preprocessShader(fragCode, {"LIGHT_TYPE_POINT"})),
}


--- @class ForwardMaterial: BaseMaterial
---
--- @field shininess number
--- @field diffuseTexture love.Texture
--- @field normalMap love.Texture
---
--- @overload fun(model: Model, aiMat: table): ForwardMaterial
local FRMaterial = Material:extend("ForwardMaterial")


function FRMaterial:new(model, matData)
    local attributes = {
        shininess            = {uniform = "u_shininess",      value = 32 --[[mat:shininess()]]},
        diffuseTexture       = {uniform = "u_diffuseTexture", value = model:getTexture(matData, "diffuse")},
        normalMap            = {uniform = "u_normalMap",      value = model:getTexture(matData, "normals")},
    }

    Material.new(self, model, lightShaders[SpotLight], attributes)
end


--- @param lightClass BaseLight
function FRMaterial:setLightType(lightClass)
    self.shader = lightShaders[lightClass]
end


return FRMaterial