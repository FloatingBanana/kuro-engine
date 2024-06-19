local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local depthShader = Utils.newPreProcessedShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class DirectionalLight: BaseLight
---
--- @field public position Vector3
--- @field public color number[]
--- @field public specular number[]
--- @field public nearPlane number
--- @field public farPlane number
---
--- @field private viewProjMatrix Matrix
---
--- @overload fun(position: Vector3, color: table, specular: table): DirectionalLight
local Dirlight = BaseLight:extend("DirectionalLight")


function Dirlight:new(position, color, specular)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_DIRECTIONAL, depthShader)

    self.position = position
    self.color = color
    self.specular = specular
    self.viewProjMatrix = Matrix.Identity()
    self.nearPlane = 0.1
    self.farPlane = 50

    self:createShadowMapTexture(2048, "2d")
end


---@param meshes table<integer, MeshPartConfig>
function Dirlight:drawShadows(shader, meshes)
    local viewMatrix = Matrix.CreateLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    local projMatrix = Matrix.CreateOrthographicOffCenter(-10, 10, 10, -10, self.nearPlane, self.farPlane)
    self.viewProjMatrix = viewMatrix * projMatrix

    love.graphics.setCanvas {depthstencil = self.shadowmap}
    love.graphics.clear()
    shader:send("lightDir", self.position.normalized:toFlatTable())
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
function Dirlight:sendLightData(shader)
    shader:sendUniform("u_lightShadowMap", self.shadowmap)
    shader:sendUniform("u_lightMatrix", "column", self.viewProjMatrix:toFlatTable())

    shader:sendUniform("light.direction", self.position.normalized:toFlatTable())

    shader:sendUniform("light.color", self.color)
    shader:sendUniform("light.specular", self.specular)
end


return Dirlight