local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local canvasTable = {}

--- @class SpotLight: BaseLight
---
--- @field position Vector3
--- @field direction Vector3
--- @field color number[]
--- @field specular number[]
--- @field innerAngle number
--- @field outerAngle number
--- @overload fun(position: Vector3, direction: Vector3, innerAngle: number, outerAngle: number, color: table, specular: table): SpotLight
local Spotlight = BaseLight:extend("SpotLight")


function Spotlight:new(position, direction, innerAngle, outerAngle, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_SPOT, true)

    self.position = position
    self.direction = direction

    self.color = color
    self.specular = specular

    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.nearPlane = 0.1
    self.farPlane = 20

    self:createShadowMapTexture(1024, "2d")
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function Spotlight:drawShadows(shader, meshparts)
    local viewMatrix = Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local projMatrix = Matrix.CreatePerspectiveFOV(self.outerAngle * 2, -1, self.nearPlane, self.farPlane)

    self.viewProjMatrix = viewMatrix:multiply(projMatrix)
    canvasTable.depthstencil = self.shadowMap

    love.graphics.setCanvas(canvasTable)
    love.graphics.clear()

    shader:sendUniform("uViewProjMatrix", "column", self.viewProjMatrix)
    shader:sendUniform("light.position", self.direction)

    for i, config in ipairs(meshparts) do
        if config.castShadows then
            shader:sendMeshConfigUniforms(config)
            config.meshPart:draw()
        end
    end
end


--- @param shader ShaderEffect
function Spotlight:sendLightData(shader)
    if self.castShadows then
        shader:trySendUniform("light.shadowMap", self.shadowMap)
        shader:trySendUniform("light.lightMatrix", "column", self.viewProjMatrix)
    end

    shader:trySendUniform("light.position",    self.position)
    shader:trySendUniform("light.color",       self.color)
    shader:trySendUniform("light.specular",    self.specular)

    shader:trySendUniform("light.direction",   self.direction)
    shader:trySendUniform("light.cutOff",      math.cos(self.innerAngle))
    shader:trySendUniform("light.outerCutOff", math.cos(self.outerAngle))
end


return Spotlight