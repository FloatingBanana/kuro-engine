local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3DRenderer.lights.baseLight"
local Dirlight = BaseLight:extend()

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")

function Dirlight:new(position, ambient, diffuse, specular)
    BaseLight.new(self, position, ambient, diffuse, specular, depthShader, 2048)
end

function Dirlight:setupLightData(meshparts, dataList, index)
    local view = Matrix.createLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local proj = Matrix.createOrthographicOffCenter(-10, 10, 10, -10, self.near, self.far)
    local viewProj = view * proj
    local direction = self.position.normalized

    self:beginLighting(viewProj)
    depthShader:send("lightDir", direction:toFlatTable())

    for part, worldMatrix in pairs(meshparts) do ---@cast worldMatrix Matrix
        depthShader:send("u_world", "column", worldMatrix:toFlatTable())
        depthShader:send("u_invTranspWorld", "column", worldMatrix.inverse:transpose():to3x3():toFlatTable())

        lg.draw(part.mesh)
    end
    self:endLighting()

    dataList.u_lightShadowMap[index] = self.shadowmap
    dataList.u_lightMatrix[index] = {viewProj:transpose():split()}

    dataList.u_lightDirection[index] = {direction:split()}

    dataList.u_lightAmbient[index] = self.ambient
    dataList.u_lightDiffuse[index] = self.diffuse
    dataList.u_lightSpecular[index] = self.specular
end

return Dirlight