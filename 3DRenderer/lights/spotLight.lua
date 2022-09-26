local Matrix = require "engine.matrix"
local Vector3 = require "engine.vector3"
local Vector2   = require "engine.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local Spotlight = BaseLight:extend()

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")

function Spotlight:new(position, direction, innerAngle, outerAngle, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, 512)

    self.direction = direction
    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.near = 1
    self.far = 50
end

function Spotlight:applyLighting(parts, index)
    local view = Matrix.createLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local proj = Matrix.createPerspectiveFOV(self.outerAngle * 2, -1, self.near, self.far)
    local viewProj = view * proj
    local fieldName = ("u_spotLights[%d]"):format(index)

    self:beginLighting(depthShader, viewProj)
    depthShader:send("lightDir", self.direction:toFlatTable())

    for part, worldMatrix in pairs(parts) do
        depthShader:send("u_world", "column", worldMatrix:toFlatTable())
        depthShader:send("u_invTranspWorld", "column", worldMatrix.inverse:transpose():to3x3():toFlatTable())

        lg.draw(part.mesh)

        part.material.shader:send(fieldName..".enabled",   self.enabled)
        part.material.shader:send(fieldName..".shadowMap", self.shadowmap)
        part.material.shader:send(fieldName..".mapSize",   self.shadowmap:getWidth())

        part.material.shader:send(fieldName..".position",    self.position:toFlatTable())
        part.material.shader:send(fieldName..".direction",   self.direction:toFlatTable())
        part.material.shader:send(fieldName..".cutOff",      math.cos(self.innerAngle))
        part.material.shader:send(fieldName..".outerCutOff", math.cos(self.outerAngle))

        part.material.shader:send(fieldName..".ambient",  self.ambient)
        part.material.shader:send(fieldName..".diffuse",  self.diffuse)
        part.material.shader:send(fieldName..".specular", self.specular)

        part.material.shader:send(fieldName..".lightMatrix", "column", viewProj:toFlatTable())
    end
    self:endLighting()
end

return Spotlight