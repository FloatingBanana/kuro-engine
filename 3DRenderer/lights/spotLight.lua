local Matrix = require "engine.matrix"
local Vector3 = require "engine.vector3"
local Vector2   = require "engine.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local Spotlight = BaseLight:extend()

function Spotlight:new(position, direction, innerAngle, outerAngle, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, Vector2(2048))

    self.direction = direction
    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.near = 2
    self.far = 50
end

function Spotlight:applyLighting(parts, index)
    local view = Matrix.createLookAt(self.position, self.position + self.direction, Vector3(0,1,0))
    local proj = Matrix.createPerspectiveOffCenter(-10, 10, 10, -10, self.near, self.far)
    local viewProj = view * proj
    local fieldName = ("u_spotLights[%d]"):format(index)

    self:beginLighting(view, proj, self.direction)

    for part, worldMatrix in pairs(parts) do
        local itw = worldMatrix.inverse:transpose()

        self.depthShader:send("u_world", "column", worldMatrix:toFlatTable())
        self.depthShader:send("u_invTranspWorld", "column", {itw.m11, itw.m12, itw.m13, itw.m21, itw.m22, itw.m23, itw.m31, itw.m32, itw.m33})
        self.depthShader:send("u_viewProj", "column", viewProj:toFlatTable())
        self.depthShader:send("lightDir", self.direction:toFlatTable())

        lg.draw(part.mesh)

        part.material.shader:send(fieldName..".enabled",     self.enabled)
        part.material.shader:send(fieldName..".shadowMap",   self.shadowmap)

        part.material.shader:send(fieldName..".position",    self.position:toFlatTable())
        part.material.shader:send(fieldName..".direction",   self.direction:toFlatTable())
        part.material.shader:send(fieldName..".cutOff",      math.cos(self.innerAngle))
        part.material.shader:send(fieldName..".outerCutOff", math.cos(self.outerAngle))

        part.material.shader:send(fieldName..".ambient",     self.ambient)
        part.material.shader:send(fieldName..".diffuse",     self.diffuse)
        part.material.shader:send(fieldName..".specular",    self.specular)

        part.material.shader:send("u_lightViewProj", "column", viewProj:toFlatTable())
    end
    self:endLighting()
end

return Spotlight