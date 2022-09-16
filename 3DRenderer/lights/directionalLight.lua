local Matrix = require "engine.matrix"
local Vector3 = require "engine.vector3"
local Vector2   = require "engine.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local Dirlight = BaseLight:extend()

local depthShader = lg.newShader("engine/3DRenderer/lights/shaders/depthMapping.glsl")

function Dirlight:new(position, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, 2048)
end

function Dirlight:applyLighting(parts, index)
    local view = Matrix.createLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local proj = Matrix.createOrthographicOffCenter(-10, 10, 10, -10, self.near, self.far)
    local viewProj = view * proj
    local fieldName = ("u_directionalLights[%d]"):format(index)

    self:beginLighting(depthShader, viewProj)
    depthShader:send("lightDir", self.position.normalized:toFlatTable())

    for part, worldMatrix in pairs(parts) do
        depthShader:send("u_world", "column", worldMatrix:toFlatTable())
        depthShader:send("u_invTranspWorld", "column", worldMatrix.inverse:transpose():to3x3():toFlatTable())

        lg.draw(part.mesh)

        part.material.shader:send(fieldName..".enabled",   self.enabled)
        part.material.shader:send(fieldName..".shadowMap", self.shadowmap)
        part.material.shader:send(fieldName..".mapSize",   self.shadowmap:getWidth())

        part.material.shader:send(fieldName..".position", self.position:toFlatTable())
        
        part.material.shader:send(fieldName..".ambient",  self.ambient)
        part.material.shader:send(fieldName..".diffuse",  self.diffuse)
        part.material.shader:send(fieldName..".specular", self.specular)

        -- FIXME: this should be in the light instance
        part.material.shader:send("u_lightViewProj", "column", viewProj:toFlatTable())
    end
    self:endLighting()
end

return Dirlight