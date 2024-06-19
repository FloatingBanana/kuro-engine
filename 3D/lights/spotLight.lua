local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local depthShader = Utils.newPreProcessedShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class SpotLight: BaseLight
---
--- @field position Vector3
--- @field direction Vector3
--- @field color number[]
--- @field specular number[]
--- @field innerAngle number
--- @field outerAngle number
--- @overload fun(position: Vector3, direction: Vector3, innerAngle: number, outerAngle: number, color: table, specular: table): SpotLight
local Spotlight = BaseLight:extend("SpotLight")


function Spotlight:new(position, direction, innerAngle, outerAngle, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_SPOT, depthShader)

    self.position = position
    self.direction = direction

    self.color = color
    self.specular = specular

    self.innerAngle = innerAngle
    self.outerAngle = outerAngle

    self.nearPlane = 0.1
    self.farPlane = 20

    self:createShadowMapTexture(1024, "2d")
end


---@param meshes table<integer, MeshPartConfig>
function Spotlight:drawShadows(shader, meshes)
    local viewMatrix = Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    local projMatrix = Matrix.CreatePerspectiveFOV(self.outerAngle * 2, -1, self.nearPlane, self.farPlane)
    self.viewProjMatrix = viewMatrix * projMatrix

    love.graphics.setCanvas {depthstencil = self.shadowmap}
    love.graphics.clear()
    shader:send("lightDir", self.direction:toFlatTable())
    shader:send("u_viewProj", "column", self.viewProjMatrix:toFlatTable())

    for i, config in ipairs(meshes) do
        if config.castShadows then
            if config.animator then
                shader:send("u_boneMatrices", "column", config.animator.finalMatrices)
            end

            shader:send("u_world", "column", config.worldMatrix:toFlatTable())
            shader:send("u_invTranspWorld", "column", config.worldMatrix.inverse:transpose():to3x3():toFlatTable())

            love.graphics.draw(config.meshPart.buffer)
        end
    end
end


--- @param shader ShaderEffect
function Spotlight:sendLightData(shader)
    shader:sendUniform("u_lightShadowMap", self.shadowmap)
    shader:sendUniform("u_lightMatrix", "column", self.viewProjMatrix)

    shader:sendUniform("light.position",    self.position)
    shader:sendUniform("light.color",       self.color)
    shader:sendUniform("light.specular",    self.specular)

    shader:sendUniform("light.direction",   self.direction)
    shader:sendUniform("light.cutOff",      math.cos(self.innerAngle))
    shader:sendUniform("light.outerCutOff", math.cos(self.outerAngle))
end


return Spotlight