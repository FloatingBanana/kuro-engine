local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local CameraFrustum = require "engine.misc.cameraFrustum"


local frustum = CameraFrustum()
local canvasTable = {depthstencil = {}}
local dirs = {
    {dir = Vector3( 1, 0, 0), up = Vector3(0,-1, 0)},
    {dir = Vector3(-1, 0, 0), up = Vector3(0,-1, 0)},
    {dir = Vector3( 0, 1, 0), up = Vector3(0, 0, 1)},
    {dir = Vector3( 0,-1, 0), up = Vector3(0, 0,-1)},
    {dir = Vector3( 0, 0, 1), up = Vector3(0,-1, 0)},
    {dir = Vector3( 0, 0,-1), up = Vector3(0,-1, 0)},
}


--- @class PointLight: BaseLight
---
--- @field public position Vector3
--- @field public color number[]
--- @field public specular number[]
--- @field public constant number
--- @field public linear number
--- @field public quadratic number
--- @field public nearPlane number
--- @field public farPlane number
---
--- @overload fun(position: Vector3, constant: number, linear: number, quadratic: number, color: table, specular: table): PointLight
local PointLight = BaseLight:extend("PointLight")


function PointLight:new(position, constant, linear, quadratic, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_POINT)

    self.position = position
    self.color = color
    self.specular = specular

    self.linear = linear
    self.constant = constant
    self.quadratic = quadratic

    self.nearPlane = 0.1
    self.farPlane = self:getLightRadius()
end


---@param size integer
---@param isStatic boolean
---@return self
function PointLight:setShadowMapping(size, isStatic)
    BaseLight.setShadowMapping(self, size, isStatic)
    self.shadowMap = BaseLight.CreateShadowMapTexture(size, "cube")

    return self
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function PointLight:drawShadows(shader, meshparts)
    self.farPlane = self:getLightRadius()
    local proj = Matrix.CreatePerspectiveFOV(math.pi/2, 1, self.nearPlane, self.farPlane)

    shader:sendUniform("light.position", self.position)
    shader:sendUniform("light.farPlane", self.farPlane)

    
    for i = 1, 6 do
        local viewProj = Matrix.CreateLookAtDirection(self.position, dirs[i].dir, dirs[i].up):multiply(proj)
        canvasTable.depthstencil[1] = self.shadowMap
        canvasTable.depthstencil.face = i
        
        love.graphics.setCanvas(canvasTable)
        love.graphics.clear()
        
        shader:sendUniform("uViewProjMatrix", "column", viewProj)
        frustum:updatePlanes(viewProj)

        for j, config in ipairs(meshparts) do
            if self:canMeshCastShadow(config) and frustum:testIntersection(config.meshPart.aabb, config.worldMatrix) then
                shader:sendMeshConfigUniforms(config)
                config.meshPart:draw()
            end
        end
    end
end


--- @param shader ShaderEffect
--- @param lightUniform string
function PointLight:sendLightData(shader, lightUniform)
    if self.shadowMap then
        shader:trySendUniform(lightUniform..".pointShadowMap", self.shadowMap)
    end

    shader:trySendUniform(lightUniform..".position",  self.position)
    shader:trySendUniform(lightUniform..".color",     self.color)
    shader:trySendUniform(lightUniform..".specular",  self.specular)
    shader:trySendUniform(lightUniform..".constant",  self.constant)
    shader:trySendUniform(lightUniform..".linear",    self.linear)
    shader:trySendUniform(lightUniform..".quadratic", self.quadratic)
    shader:trySendUniform(lightUniform..".farPlane",  self.farPlane)

end


local treshold = 256/5
function PointLight:getLightRadius()
    local linear, constant, quadratic = self.linear, self.constant, self.quadratic
    local color = self.color + self.specular
    local max = math.max(math.max(color.r, color.g), color.b)

    return (-linear + math.sqrt(linear * linear - 4 * quadratic * (constant - treshold * max))) / (2 * quadratic)
end


return PointLight