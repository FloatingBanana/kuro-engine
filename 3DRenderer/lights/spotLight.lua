local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local Vector2   = require "engine.math.vector2"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local Spotlight = BaseLight:extend()

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")

function Spotlight:new(position, direction, innerAngle, outerAngle, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, depthShader, 512)

    self.direction = direction
    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.near = 1
    self.far = 50
end

function Spotlight:setupLightData(meshparts, dataList, index)
    local view = Matrix.createLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local proj = Matrix.createPerspectiveFOV(self.outerAngle * 2, -1, self.near, self.far)
    local viewProj = view * proj

    self:beginLighting(viewProj)
    depthShader:send("lightDir", self.direction:toFlatTable())

    for part, worldMatrix in pairs(meshparts) do ---@cast worldMatrix Matrix

        depthShader:send("u_world", "column", worldMatrix:toFlatTable())
        depthShader:send("u_invTranspWorld", "column", worldMatrix.inverse:transpose():to3x3():toFlatTable())
        lg.draw(part.mesh)

    end
    self:endLighting()

    dataList.u_lightShadowMap[index] = self.shadowmap
    dataList.u_lightMatrix[index] = {viewProj:transpose():split()}

    dataList.u_lightPosition[index] = {self.position:split()}
    dataList.u_lightDirection[index] = {self.direction:split()}
    dataList.u_lightVars[index] = {math.cos(self.innerAngle), math.cos(self.outerAngle), 0, 0}

    dataList.u_lightAmbient[index] = self.ambient
    dataList.u_lightDiffuse[index] = self.diffuse
    dataList.u_lightSpecular[index] = self.specular
end

return Spotlight