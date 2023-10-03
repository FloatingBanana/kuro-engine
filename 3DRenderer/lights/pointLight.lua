local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3DRenderer.lights.baseLight"

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/pointShadowMapRenderer.glsl")

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
--- @field constant number
--- @field linear number
--- @field quadratic number
--- @overload fun(position: Vector3, constant: number, linear: number, quadratic: number, diffuse: table, specular: table): PointLight
local PointLight = BaseLight:extend()


function PointLight:new(position, constant, linear, quadratic, diffuse, specular)
    BaseLight.new(self, position, diffuse, specular, depthShader)

    self.linear = linear
    self.constant = constant
    self.quadratic = quadratic

    self.near = 0.1
    self.far = self:getLightRadius()

    self.shadowmap = lg.newCanvas(256, 256, {format = "depth24", type = "cube", readable = true})
end


function PointLight:generateShadowMap(meshparts)
    local proj = Matrix.CreatePerspectiveFOV(math.rad(90), 1, self.near, self.far)

    depthShader:send("lightPos", self.position:toFlatTable())
    depthShader:send("farPlane", self.far)

    for i = 1, 6 do
        local view = Matrix.CreateLookAtDirection(self.position, dirs[i].dir, dirs[i].up)
        local viewProj = view * proj

        self:beginShadowMapping(viewProj, i)

        for part, settings in pairs(meshparts) do
            if settings.castShadows then
                local worldMatrix = settings.worldMatrix --- @type Matrix

                depthShader:send("u_world", "column", worldMatrix:toFlatTable())
                lg.draw(part.mesh)
            end
        end

        self:endShadowMapping()
    end
end


function PointLight:applyLighting(lightingShader)
    lightingShader:send("u_pointLightShadowMap", self.shadowmap)

    lightingShader:send("light.position", self.position:toFlatTable())
    lightingShader:send("light.constant", self.constant)
    lightingShader:send("light.linear", self.linear)
    lightingShader:send("light.quadratic", self.quadratic)
    lightingShader:send("light.farPlane", self.far)

    lightingShader:send("light.diffuse", self.diffuse)
    lightingShader:send("light.specular", self.specular)
end


local treshold = 256/5
function PointLight:getLightRadius()
    local linear, constant, quadratic = self.linear, self.constant, self.quadratic
    local color = self.diffuse + self.specular
    local max = math.max(math.max(color.r, color.g), color.b)

    return (-linear + math.sqrt(linear * linear - 4 * quadratic * (constant - treshold * max))) / (2 * quadratic)
end


return PointLight