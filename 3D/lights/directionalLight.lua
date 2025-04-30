local Matrix4 = require "engine.math.matrix4"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local CameraFrustum = require "engine.misc.cameraFrustum"

local frustum = CameraFrustum()
local canvasTable = {}


--- @class DirectionalLight: BaseLight
---
--- @field public position Vector3
--- @field public direction Vector3
--- @field public color number[]
--- @field public specular number[]
--- @field public nearPlane number
--- @field public farPlane number
---
--- @field private viewProjMatrix Matrix4
---
--- @overload fun(position: Vector3, direction: Vector3, color: table, specular: table): DirectionalLight
local Dirlight = BaseLight:extend("DirectionalLight")


function Dirlight:new(position, direction, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_DIRECTIONAL)

    self.position = position
    self.direction = direction
    self.color = color
    self.specular = specular
    self.viewProjMatrix = Matrix4.Identity()
    self.nearPlane = 0.1
    self.farPlane = 100
    self.projectionSize = 20
end


---@param size integer
---@param isStatic boolean
---@return self
function Dirlight:setShadowMapping(size, isStatic)
    BaseLight.setShadowMapping(self, size, isStatic)
    self.shadowMap = BaseLight.CreateShadowMapTexture(size, "2d")

    return self
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function Dirlight:drawShadows(shader, meshparts)
    local viewMatrix = Matrix4.CreateLookAtDirection(self.position, -self.direction, Vector3(0,1,0))
    local projMatrix = Matrix4.CreateOrthographicOffCenter(-self.projectionSize, self.projectionSize, -self.projectionSize, self.projectionSize, self.nearPlane, self.farPlane)

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
function Dirlight:sendLightData(shader, lightUniform)
    if self.shadowMap then
        shader:trySendUniform(lightUniform..".shadowMap", self.shadowMap)
        shader:trySendUniform(lightUniform..".lightMatrix", "column", self.viewProjMatrix)
    end

    shader:trySendUniform(lightUniform..".type",      self.typeDefinition)
    shader:trySendUniform(lightUniform..".direction", self.direction)
    shader:trySendUniform(lightUniform..".color",     self.color)
    shader:trySendUniform(lightUniform..".specular",  self.specular)
end


return Dirlight