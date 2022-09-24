local Matrix = require "engine.matrix"
local Vector3 = require "engine.vector3"
local Vector2   = require "engine.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local PointLight = BaseLight:extend()

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/pointShadowMapRenderer.glsl")

function PointLight:new(position, linear, constant, quadratic, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, 1)

    self.linear = linear
    self.constant = constant
    self.quadratic = quadratic

    self.near = 1
    self.far = 15

    self.shadowmap = lg.newCanvas(256, 256, {format = "depth24", type = "cube", readable = true})
end

local dirs = {
    {dir = Vector3( 1, 0, 0), up = Vector3(0,-1, 0)},
    {dir = Vector3(-1, 0, 0), up = Vector3(0,-1, 0)},
    {dir = Vector3( 0, 1, 0), up = Vector3(0, 0, 1)},
    {dir = Vector3( 0,-1, 0), up = Vector3(0, 0,-1)},
    {dir = Vector3( 0, 0, 1), up = Vector3(0,-1, 0)},
    {dir = Vector3( 0, 0,-1), up = Vector3(0,-1, 0)},
}

function PointLight:applyLighting(parts, index)
    local proj = Matrix.createPerspectiveFOV(math.rad(90), 1, self.near, self.far)
    local fieldName = ("u_pointLights[%d]"):format(index)

    depthShader:send("lightPos", self.position:toFlatTable())
    depthShader:send("farPlane", self.far)

    for i = 1, 6 do
        local view = Matrix.createLookAtDirection(self.position, dirs[i].dir, dirs[i].up)
        local viewProj = view * proj

        self:beginLighting(depthShader, viewProj, i)

        for part, worldMatrix in pairs(parts) do
            depthShader:send("u_world", "column", worldMatrix:toFlatTable())

            lg.draw(part.mesh)

            if i == 6 then
                part.material.shader:send(fieldName..".enabled",   self.enabled)
                part.material.shader:send(fieldName..".shadowMap", self.shadowmap)

                part.material.shader:send(fieldName..".position", self.position:toFlatTable())

                part.material.shader:send(fieldName..".constant",  self.constant)
                part.material.shader:send(fieldName..".linear",    self.linear)
                part.material.shader:send(fieldName..".quadratic", self.quadratic)

                part.material.shader:send(fieldName..".farPlane",  self.far)

                part.material.shader:send(fieldName..".ambient",  self.ambient)
                part.material.shader:send(fieldName..".diffuse",  self.diffuse)
                part.material.shader:send(fieldName..".specular", self.specular)
            end
        end

        self:endLighting()
    end
end

return PointLight