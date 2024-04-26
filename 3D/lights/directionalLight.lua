local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"
local Utils = require "engine.misc.utils"

local depthShader = Utils.newPreProcessedShader("engine/shaders/3D/shadowMap/shadowMapRenderer.glsl")


--- @class DirectionalLight: BaseLight
---
--- @field viewMatrix Matrix
--- @field projMatrix Matrix
--- @field viewProjMatrix Matrix
---
--- @overload fun(position: Vector3, diffuse: table, specular: table): DirectionalLight
local Dirlight = BaseLight:extend("DirectionalLight")


function Dirlight:new(position, diffuse, specular)
    BaseLight.new(self, position, diffuse, specular, depthShader)

    self.shadowmap = love.graphics.newCanvas(2048, 2048, {format = "depth16", readable = true})
    self.shadowmap:setFilter("linear", "linear")
    self.shadowmap:setWrap("clamp")
    self.shadowmap:setDepthSampleMode("less")

    self.viewMatrix = Matrix.Identity()
    self.projMatrix = Matrix.Identity()
    self.viewProjMatrix = Matrix.Identity()
end


---@param meshes table<integer, MeshPartConfig>
function Dirlight:drawShadows(shader, meshes)
    self.viewMatrix = Matrix.CreateLookAt(self.position, Vector3(0,0,0), Vector3(0,1,0))
    self.projMatrix = Matrix.CreateOrthographicOffCenter(-10, 10, 10, -10, self.near, self.far)
    self.viewProjMatrix = self.viewMatrix * self.projMatrix

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


function Dirlight:applyLighting(lightingShader)
    lightingShader:send("u_lightShadowMap", self.shadowmap)
    lightingShader:send("u_lightMatrix", "column", self.viewProjMatrix:toFlatTable())

    lightingShader:send("light.direction", self.position.normalized:toFlatTable())

    lightingShader:send("light.diffuse", self.diffuse)
    lightingShader:send("light.specular", self.specular)
end


return Dirlight