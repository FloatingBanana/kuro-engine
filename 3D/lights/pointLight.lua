local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"


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
    BaseLight.new(self, BaseLight.LIGHT_TYPE_POINT, true)

    self.position = position
    self.color = color
    self.specular = specular

    self.linear = linear
    self.constant = constant
    self.quadratic = quadratic

    self.nearPlane = 0.1
    self.farPlane = self:getLightRadius()

    self:createShadowMapTexture(256, "cube")
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function PointLight:drawShadows(shader, meshparts)
    self.farPlane = self:getLightRadius()

    local proj = Matrix.CreatePerspectiveFOV(math.pi/2, 1, 0.1, self.farPlane)

    shader:sendUniform("light.position", self.position)
    shader:sendUniform("light.farPlane", self.farPlane)

    for i = 1, 6 do
        local view = Matrix.CreateLookAtDirection(self.position, dirs[i].dir, dirs[i].up)
        local viewProj = view * proj
        canvasTable.depthstencil[1] = self.shadowMap
        canvasTable.depthstencil.face = i

        love.graphics.setCanvas(canvasTable)
        love.graphics.clear()

        shader:sendUniform("uViewProjMatrix", "column", viewProj)

        for j, config in ipairs(meshparts) do
            if config.castShadows then
                shader:sendMeshConfigUniforms(config)
                config.meshPart:draw()
            end
        end
    end
end


--- @param shader ShaderEffect
function PointLight:sendLightData(shader)
    if self.castShadows then
        shader:sendUniform("u_pointLightShadowMap", self.shadowMap)
    end

    shader:sendUniform("light.position",  self.position)
    shader:sendUniform("light.color",     self.color)
    shader:sendUniform("light.specular",  self.specular)
    shader:sendUniform("light.constant",  self.constant)
    shader:sendUniform("light.linear",    self.linear)
    shader:sendUniform("light.quadratic", self.quadratic)
    shader:sendUniform("light.farPlane",  self.farPlane)

end


local treshold = 256/5
function PointLight:getLightRadius()
    local linear, constant, quadratic = self.linear, self.constant, self.quadratic
    local color = self.color + self.specular
    local max = math.max(math.max(color.r, color.g), color.b)

    return (-linear + math.sqrt(linear * linear - 4 * quadratic * (constant - treshold * max))) / (2 * quadratic)
end


return PointLight