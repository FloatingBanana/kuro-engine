local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3DRenderer.lights.baseLight"

local depthShader = lg.newShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class SpotLight: BaseLight
---
--- @field direction Vector3
--- @field innerAngle number
--- @field outerAngle number
--- @overload fun(position: Vector3, direction: Vector3, innerAngle: number, outerAngle: number, diffuse: table, specular: table): SpotLight
local Spotlight = BaseLight:extend()


function Spotlight:new(position, direction, innerAngle, outerAngle, diffuse, specular)
    BaseLight.new(self, position, diffuse, specular, depthShader)

    self.direction = direction
    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.near = 1
    self.far = 50

    self.shadowmap = lg.newCanvas(1024, 1024, {format = "depth16", readable = true})
    self.shadowmap:setFilter("nearest", "nearest")
    self.shadowmap:setWrap("clamp")
end


function Spotlight:generateShadowMap(meshparts)
    local view = Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local proj = Matrix.CreatePerspectiveFOV(self.outerAngle * 2, -1, self.near, self.far)
    local viewProj = view * proj

    self:beginShadowMapping(viewProj)
    depthShader:send("lightDir", self.direction:toFlatTable())

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


function Spotlight:applyLighting(lightingShader)
    local view = Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local proj = Matrix.CreatePerspectiveFOV(self.outerAngle * 2, -1, self.near, self.far)
    local viewProj = view * proj

    lightingShader:send("u_lightShadowMap", self.shadowmap)
    lightingShader:send("u_lightMatrix", viewProj:transpose():toFlatTable())

    lightingShader:send("light.position", self.position:toFlatTable())
    lightingShader:send("light.direction", self.direction:toFlatTable())
    lightingShader:send("light.cutOff", math.cos(self.innerAngle))
    lightingShader:send("light.outerCutOff", math.cos(self.outerAngle))

    lightingShader:send("light.diffuse", self.diffuse)
    lightingShader:send("light.specular", self.specular)
end


return Spotlight