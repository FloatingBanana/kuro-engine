local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local depthShader = Utils.newPreProcessedShader("engine/shaders/3D/shadowMap/pointShadowMapRenderer.glsl")

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
--- @overload fun(position: Vector3, constant: number, linear: number, quadratic: number, color: table, specular: table): PointLight
local PointLight = BaseLight:extend("PointLight")


function PointLight:new(position, constant, linear, quadratic, color, specular)
    BaseLight.new(self, position, color, specular, depthShader)

    self.linear = linear
    self.constant = constant
    self.quadratic = quadratic

    self.near = 0.1
    self.far = self:getLightRadius()

    self.shadowmap = love.graphics.newCanvas(256, 256, {format = "depth16", type = "cube", readable = true})
    self.shadowmap:setFilter("linear", "linear")
    self.shadowmap:setDepthSampleMode("less")
end


---@param meshes table<integer, MeshPartConfig>
function PointLight:drawShadows(shader, meshes)
    local proj = Matrix.CreatePerspectiveFOV(math.rad(90), 1, self.near, self.far)

    shader:send("lightPos", self.position:toFlatTable())
    shader:send("farPlane", self.far)

    for i = 1, 6 do
        local view = Matrix.CreateLookAtDirection(self.position, dirs[i].dir, dirs[i].up)
        local viewProj = view * proj

        love.graphics.setCanvas {depthstencil = {self.shadowmap, face = i}}
        love.graphics.clear()
        shader:send("u_viewProj", "column", viewProj:toFlatTable())

        for j, config in ipairs(meshes) do
            if config.castShadows then
                shader:send("u_world", "column", config.worldMatrix:toFlatTable())

                if config.animator then
                    shader:send("u_boneMatrices", "column", config.animator.finalMatrices)
                end

                love.graphics.draw(config.meshPart.buffer)
            end
        end
    end
end


function PointLight:applyLighting(lightingShader)
    lightingShader:send("u_pointLightShadowMap", self.shadowmap)

    lightingShader:send("light.position", self.position:toFlatTable())
    lightingShader:send("light.constant", self.constant)
    lightingShader:send("light.linear", self.linear)
    lightingShader:send("light.quadratic", self.quadratic)
    lightingShader:send("light.farPlane", self.far)

    lightingShader:send("light.color", self.color)
    lightingShader:send("light.specular", self.specular)
end


local treshold = 256/5
function PointLight:getLightRadius()
    local linear, constant, quadratic = self.linear, self.constant, self.quadratic
    local color = self.color + self.specular
    local max = math.max(math.max(color.r, color.g), color.b)

    return (-linear + math.sqrt(linear * linear - 4 * quadratic * (constant - treshold * max))) / (2 * quadratic)
end


function PointLight:getLightTypeDefinition()
    return "LIGHT_TYPE_POINT"
end


return PointLight