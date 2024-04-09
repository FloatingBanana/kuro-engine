local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local depthShader = Utils.newPreProcessedShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class SpotLight: BaseLight
---
--- @field direction Vector3
--- @field innerAngle number
--- @field outerAngle number
--- @field viewMatrix Matrix
--- @field projMatrix Matrix
--- @field viewProjMatrix Matrix
--- @overload fun(position: Vector3, direction: Vector3, innerAngle: number, outerAngle: number, diffuse: table, specular: table): SpotLight
local Spotlight = BaseLight:extend("SpotLight")


function Spotlight:new(position, direction, innerAngle, outerAngle, diffuse, specular)
    BaseLight.new(self, position, diffuse, specular, depthShader)

    self.direction = direction
    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.near = 1
    self.far = 50

    self.shadowmap = love.graphics.newCanvas(1024, 1024, {format = "depth16", readable = true})
    self.shadowmap:setFilter("nearest", "nearest")
    self.shadowmap:setWrap("clamp")

    self.viewMatrix = Matrix.Identity()
    self.projMatrix = Matrix.Identity()
    self.viewProjMatrix = Matrix.Identity()
end


---@param meshes table<integer, MeshPartConfig>
function Spotlight:generateShadowMap(meshes)
    self.viewMatrix = Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    self.projMatrix = Matrix.CreatePerspectiveFOV(self.outerAngle * 2, -1, self.near, self.far)
    self.viewProjMatrix = self.viewMatrix * self.projMatrix

    self:beginShadowMapping(self.viewProjMatrix)
    depthShader:send("lightDir", self.direction:toFlatTable())

    for i, config in ipairs(meshes) do
        if config.castShadows then
            local animator = config.animator
            if animator then
                depthShader:send("u_boneMatrices", "column", animator.finalMatrices)
            end

            depthShader:send("u_world", "column", config.worldMatrix:toFlatTable())
            depthShader:send("u_invTranspWorld", "column", config.worldMatrix.inverse:transpose():to3x3():toFlatTable())

            love.graphics.draw(config.meshPart.buffer)
        end
    end
    self:endShadowMapping()
end


function Spotlight:applyLighting(lightingShader)
    lightingShader:send("u_lightShadowMap", self.shadowmap)
    lightingShader:send("u_lightMatrix", "column", self.viewProjMatrix:toFlatTable())

    lightingShader:send("light.position",    self.position:toFlatTable())
    lightingShader:send("light.direction",   self.direction:toFlatTable())
    lightingShader:send("light.cutOff",      math.cos(self.innerAngle))
    lightingShader:send("light.outerCutOff", math.cos(self.outerAngle))

    lightingShader:send("light.diffuse",  self.diffuse)
    lightingShader:send("light.specular", self.specular)
end


return Spotlight