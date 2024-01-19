local Lume    = require "engine.3rdparty.lume"
local Vector3 = require "engine.math.vector3"
local Utils   = require "engine.misc.utils"
local Object  = require "engine.3rdparty.classic.classic"

--- @alias MeshConfig {mesh: ModelMesh, castShadows: boolean, ignoreLighting: boolean, worldMatrix: Matrix, animator: ModelAnimator?, onDraw: function?}

--- @class BaseRenderer: Object
---
--- @field private screensize Vector2
--- @field protected ppeffects BasePostProcessingEffect[]
--- @field resultCanvas love.Canvas
--- @field depthCanvas love.Canvas
--- @field velocityBuffer love.Canvas
--- @field protected meshes table<integer, MeshConfig>
--- @field protected lights BaseLight[]
--- @field protected previousTransformations table<integer, Matrix>
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): BaseRenderer
local Renderer = Object:extend()


function Renderer:new(screensize, postProcessingEffects)
    self.screensize = screensize
    self.ppeffects = postProcessingEffects

    self.resultCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg11b10f"})
    self.depthCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "depth24stencil8", readable = true})
    self.velocityBuffer = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg8"})

    self.meshes = {}
    self.lights = {}
    self.previousTransformations = {} -- for velocity buffer
end


---@param config MeshConfig
function Renderer:addMesh(config)
    local id = #self.meshes + 1
    self.meshes[id] = config
    self.previousTransformations[id] = config.worldMatrix:clone()

    return id
end


---@param ... BaseLight
function Renderer:addLights(...)
    Lume.push(self.lights, ...)
end


---@param light BaseLight
function Renderer:removeLight(light)
    table.remove(self.lights, Lume.find(self.lights, light))
end

function Renderer:removeMesh(id)
    self.meshes[id] = nil
    self.previousTransformations[id] = nil
end


---@param meshId integer
---@return MeshConfig
function Renderer:getMeshConfig(meshId)
    return self.meshes[meshId]
end


function Renderer:renderMeshes()
    error("Not implemented")
end


---@param camera Camera3D
function Renderer:render(camera)
    camera:updateMatrices()

    love.graphics.push("all")
    self:renderMeshes(camera)
    love.graphics.pop()

    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:onPostRender(self, result, camera)
    end

    love.graphics.pop()
    love.graphics.draw(result)

    -- Store mesh transfomation from this frame to calculate the velocity buffer on the next frame
    for id, prevMatrix in pairs(self.previousTransformations) do
        local config = self:getMeshConfig(id)

        self.previousTransformations[id] = config.worldMatrix * camera.viewProjectionMatrix
    end
end


---@param shader love.Shader
---@param camera Camera3D
---@param meshId integer?
function Renderer:sendCommonBuffers(shader, camera, meshId)
	Utils.trySendUniform(shader, "uViewMatrix", "column", camera.viewMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uProjMatrix", "column", camera.projectionMatrix:toFlatTable())
    Utils.trySendUniform(shader, "uViewProjMatrix", "column", camera.viewProjectionMatrix:toFlatTable())

    Utils.trySendUniform(shader, "uInvViewMatrix", "column", camera.invViewMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uInvProjMatrix", "column", camera.invProjectionMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uInvViewProjMatrix", "column", camera.invViewProjectionMatrix:toFlatTable())

    Utils.trySendUniform(shader, "uNearPlane", camera.nearPlane)
    Utils.trySendUniform(shader, "uFarPlane", camera.farPlane)

    Utils.trySendUniform(shader, "uViewPosition", camera.position:toFlatTable())
	Utils.trySendUniform(shader, "uViewDirection", Vector3(0,0,1):transform(camera.rotation):toFlatTable())

	Utils.trySendUniform(shader, "uTime", love.timer.getTime())
	Utils.trySendUniform(shader, "uIsCanvasActive", love.graphics.getCanvas() ~= nil)
	Utils.trySendUniform(shader, "uDepthBuffer", self.depthCanvas)
	Utils.trySendUniform(shader, "uVelocityBuffer", self.velocityBuffer)

    if meshId then
        local settings = self:getMeshConfig(meshId)

        Utils.trySendUniform(shader, "uWorldMatrix", "column", settings.worldMatrix:toFlatTable())
        Utils.trySendUniform(shader, "uPrevTransform", "column", self.previousTransformations[meshId]:toFlatTable())

        if settings.animator then
            Utils.trySendUniform(shader, "uBoneMatrices", settings.animator.finalMatrices)
        end
    end
end


return Renderer