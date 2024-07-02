local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local canvasTable = {}


--- @class DirectionalLight: BaseLight
---
--- @field public position Vector3
--- @field public color number[]
--- @field public specular number[]
--- @field public nearPlane number
--- @field public farPlane number
---
--- @field private viewProjMatrix Matrix
---
--- @overload fun(position: Vector3, color: table, specular: table): DirectionalLight
local Dirlight = BaseLight:extend("DirectionalLight")


function Dirlight:new(position, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_DIRECTIONAL, true)

    self.position = position
    self.color = color
    self.specular = specular
    self.viewProjMatrix = Matrix.Identity()
    self.nearPlane = 0.1
    self.farPlane = 50

    self:createShadowMapTexture(2048, "2d")
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function Dirlight:drawShadows(shader, meshparts)
    local viewMatrix = Matrix.CreateLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local projMatrix = Matrix.CreateOrthographicOffCenter(-10, 10, 10, -10, self.nearPlane, self.farPlane)

    self.viewProjMatrix = viewMatrix:multiply(projMatrix)
    canvasTable.depthstencil = self.shadowMap

    love.graphics.setCanvas(canvasTable)
    love.graphics.clear()

    shader:sendUniform("light.direction", self.position.normalized)
    shader:sendUniform("uViewProjMatrix", "column", self.viewProjMatrix)

    for i, config in ipairs(meshparts) do
        if config.castShadows then
            shader:sendMeshConfigUniforms(config)
            config.meshPart:draw()
        end
    end
end


--- @param shader ShaderEffect
function Dirlight:sendLightData(shader)
    if self.castShadows then
        shader:sendUniform("u_lightShadowMap", self.shadowMap)
        shader:sendUniform("u_lightMatrix", "column", self.viewProjMatrix)
    end

    shader:sendUniform("light.direction", self.position.normalized)
    shader:sendUniform("light.color", self.color)
    shader:sendUniform("light.specular", self.specular)
end


return Dirlight