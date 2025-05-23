local Matrix4 = require "engine.math.matrix4"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local CameraFrustum = require "engine.misc.cameraFrustum"

local frustum = CameraFrustum()
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
    BaseLight.new(self, BaseLight.LIGHT_TYPE_SPOT)

    self.position = position
    self.direction = direction

    self.color = color
    self.specular = specular

    self.constant = 0
    self.linear = 0
    self.quadratic = 1

    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.nearPlane = 0.1
    self.farPlane = 20
end


---@param size integer
---@param isStatic boolean
---@return self
function Spotlight:setShadowMapping(size, isStatic)
    BaseLight.setShadowMapping(self, size, isStatic)
    self.shadowMap = BaseLight.CreateShadowMapTexture(size, "2d")

    return self
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function Spotlight:drawShadows(shader, meshparts)
    local viewMatrix = Matrix4.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local projMatrix = Matrix4.CreatePerspectiveFOV(self.outerAngle * 2, 1, self.nearPlane, self.farPlane)

    self.viewProjMatrix = viewMatrix:multiply(projMatrix)
    canvasTable.depthstencil = self.shadowMap

    love.graphics.setCanvas(canvasTable)
    love.graphics.clear()

    shader:sendUniform("uViewProjMatrix", "column", self.viewProjMatrix)
    frustum:updatePlanes(self.viewProjMatrix)

    for i, config in ipairs(meshparts) do
        if self:canMeshCastShadow(config) and frustum:testIntersection(config.meshPart.aabb, config.worldMatrix) then
            shader:sendMeshConfigUniforms(config)
            config.meshPart:draw()
        end
    end
end


--- @param shader ShaderEffect
--- @param lightUniform string
function Spotlight:sendLightData(shader, lightUniform)
    if self.shadowMap then
        shader:trySendUniform(lightUniform..".shadowMap", self.shadowMap)
        shader:trySendUniform(lightUniform..".lightMatrix", "column", self.viewProjMatrix)
    end

    shader:trySendUniform(lightUniform..".type",        self.typeDefinition)
    shader:trySendUniform(lightUniform..".position",    self.position)
    shader:trySendUniform(lightUniform..".color",       self.color)
    shader:trySendUniform(lightUniform..".specular",    self.specular)

    shader:trySendUniform(lightUniform..".constant",    self.constant)
    shader:trySendUniform(lightUniform..".linear",      self.linear)
    shader:trySendUniform(lightUniform..".quadratic",   self.quadratic)

    shader:trySendUniform(lightUniform..".direction",   self.direction)
    shader:trySendUniform(lightUniform..".cutOff",      math.cos(self.innerAngle))
    shader:trySendUniform(lightUniform..".outerCutOff", math.cos(self.outerAngle))
end


return Spotlight