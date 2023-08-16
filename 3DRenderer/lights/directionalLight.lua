local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3DRenderer.lights.baseLight"

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class DirectionalLight: BaseLight
---
--- @overload fun(position: Vector3, diffuse: table, specular: table): DirectionalLight
local Dirlight = BaseLight:extend()


function Dirlight:new(position, diffuse, specular)
    BaseLight.new(self, position, diffuse, specular, depthShader)

    self.shadowmap = lg.newCanvas(2048, 2048, {format = "depth16", readable = true})
    self.shadowmap:setFilter("nearest", "nearest")
    self.shadowmap:setWrap("clamp")
end


function Dirlight:generateShadowMap(meshparts)
    local view = Matrix.CreateLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local proj = Matrix.CreateOrthographicOffCenter(-10, 10, 10, -10, self.near, self.far)
    local viewProj = view * proj
    local direction = self.position.normalized

    self:beginShadowMapping(viewProj)
    depthShader:send("lightDir", direction:toFlatTable())

    for part, settings in pairs(meshparts) do
        if settings.castShadows then
            local worldMatrix = settings.worldMatrix --- @type Matrix

            depthShader:send("u_world", "column", worldMatrix:toFlatTable())
            depthShader:send("u_invTranspWorld", "column", worldMatrix.inverse:transpose():to3x3():toFlatTable())
            lg.draw(part.mesh)
        end
    end
    self:endShadowMapping()
end


function Dirlight:applyLighting(lightingShader)
    local view = Matrix.CreateLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local proj = Matrix.CreateOrthographicOffCenter(-10, 10, 10, -10, self.near, self.far)
    local viewProj = view * proj
    local direction = self.position.normalized

    lightingShader:send("u_lightShadowMap", self.shadowmap)
    lightingShader:send("u_lightMatrix", viewProj:transpose():toFlatTable())

    lightingShader:send("light.direction", direction:toFlatTable())

    -- lightingShader:send("light.ambient", self.ambient)
    lightingShader:send("light.diffuse", self.diffuse)
    lightingShader:send("light.specular", self.specular)
end


return Dirlight