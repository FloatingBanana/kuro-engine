local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local Vector2   = require "engine.math.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local PointLight = BaseLight:extend()

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/pointShadowMapRenderer.glsl")

function PointLight:new(position, linear, constant, quadratic, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, depthShader, 1)

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

function PointLight:setupLightData(meshparts, dataList, index)
    local proj = Matrix.createPerspectiveFOV(math.rad(90), 1, self.near, self.far)

    depthShader:send("lightPos", self.position:toFlatTable())
    depthShader:send("farPlane", self.far)

    for i = 1, 6 do
        local view = Matrix.createLookAtDirection(self.position, dirs[i].dir, dirs[i].up)
        local viewProj = view * proj

        self:beginLighting(viewProj, i)

        for part, worldMatrix in pairs(meshparts) do ---@cast worldMatrix Matrix
            depthShader:send("u_world", "column", worldMatrix:toFlatTable())

            lg.draw(part.mesh)
        end

        self:endLighting()
    end

    dataList.u_pointLightShadowMap[index] = self.shadowmap

    dataList.u_lightPosition[index] = {self.position:split()}
    dataList.u_lightVars[index] = {self.constant, self.linear, self.quadratic, self.far}

    dataList.u_lightAmbient[index] = self.ambient
    dataList.u_lightDiffuse[index] = self.diffuse
    dataList.u_lightSpecular[index] = self.specular
end

return PointLight