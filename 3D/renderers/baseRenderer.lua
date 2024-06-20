local Lume    = require "engine.3rdparty.lume"
local Vector3 = require "engine.math.vector3"
local Matrix  = require "engine.math.matrix"
local Stack   = require "engine.collections.stack"
local Utils   = require "engine.misc.utils"
local Object  = require "engine.3rdparty.classic.classic"

local configPool = Stack()

--- @alias MeshPartConfig {meshPart: MeshPart, material: BaseMaterial, castShadows: boolean, ignoreLighting: boolean, worldMatrix: Matrix, animator: ModelAnimator?}

--- @class BaseRenderer: Object
---
--- @field public resultCanvas love.Canvas
--- @field public depthCanvas love.Canvas
--- @field public velocityBuffer love.Canvas
--- @field public camera Camera3D
--- @field protected ppeffects BasePostProcessingEffect[]
--- @field protected meshParts Stack
--- @field protected lights BaseLight[]
--- @field private screensize Vector2
---
--- @overload fun(screenSize: Vector2, camera: Camera3D, postProcessingEffects: BasePostProcessingEffect[]): BaseRenderer
local Renderer = Object:extend("BaseRenderer")


function Renderer:new(screensize, camera, postProcessingEffects)
    self.screensize = screensize
    self.camera = camera
    self.ppeffects = postProcessingEffects
    self.meshParts = Stack()
    self.lights = {}

    self.resultCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg11b10f"})
    self.depthCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "depth24stencil8", readable = true})
    self.velocityBuffer = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg8"})

end

---@param meshPart MeshPart
---@return MeshPartConfig
function Renderer:pushMeshPart(meshPart)
    local config = configPool:pop() or {}

    config.material = meshPart.material
    config.meshPart = meshPart
    config.castShadows = true
    config.ignoreLighting = false
    config.worldMatrix = Matrix.Identity()
    config.animator = nil

    self.meshParts:push(config)
    return config
end


---@protected
---@param config MeshPartConfig
function Renderer:recycleConfigTable(config)
    config.animator = nil
    config.meshPart = nil
    config.material = nil
    configPool:push(config)
end


---@param ... BaseLight
function Renderer:addLights(...)
    Lume.push(self.lights, ...)
end


---@param light BaseLight
function Renderer:removeLight(light)
    table.remove(self.lights, Lume.find(self.lights, light))
end


function Renderer:renderMeshes()
    error("Not implemented")
end


function Renderer:render()
    self.camera:updateMatrices()

    love.graphics.push("all")
    self:renderMeshes()
    love.graphics.pop()

    assert(#self.meshParts == 0, "Failed to consume all queued meshes")

    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:onPostRender(self, result)
    end

    love.graphics.pop()
    love.graphics.draw(result)
end


---@param shader love.Shader
function Renderer:sendCommonRendererBuffers(shader)
	Utils.trySendUniform(shader, "uViewMatrix", "column", self.camera.viewMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uProjMatrix", "column", self.camera.projectionMatrix:toFlatTable())
    Utils.trySendUniform(shader, "uViewProjMatrix", "column", self.camera.viewProjectionMatrix:toFlatTable())

    Utils.trySendUniform(shader, "uInvViewMatrix", "column", self.camera.invViewMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uInvProjMatrix", "column", self.camera.invProjectionMatrix:toFlatTable())
	Utils.trySendUniform(shader, "uInvViewProjMatrix", "column", self.camera.invViewProjectionMatrix:toFlatTable())

    Utils.trySendUniform(shader, "uNearPlane", self.camera.nearPlane)
    Utils.trySendUniform(shader, "uFarPlane", self.camera.farPlane)

    Utils.trySendUniform(shader, "uViewPosition", self.camera.position:toFlatTable())
	Utils.trySendUniform(shader, "uViewDirection", Vector3(0,0,1):transform(self.camera.rotation):toFlatTable())

	Utils.trySendUniform(shader, "uTime", love.timer.getTime())
	Utils.trySendUniform(shader, "uIsCanvasActive", love.graphics.getCanvas() ~= nil)
	Utils.trySendUniform(shader, "uDepthBuffer", self.depthCanvas)
	Utils.trySendUniform(shader, "uVelocityBuffer", self.velocityBuffer)
	Utils.trySendUniform(shader, "uColorBuffer", self.resultCanvas)
end


---@param shader love.Shader
---@param config MeshPartConfig
function Renderer:sendCommonMeshBuffers(shader, config)
    Utils.trySendUniform(shader, "uWorldMatrix",   "column", config.worldMatrix:toFlatTable())
    -- Utils.trySendUniform(shader, "uPrevTransform", "column", self.previousTransformations[meshId]:toFlatTable())

    if config.animator then
        Utils.trySendUniform(shader, "uBoneMatrices", "column", config.animator.finalMatrices)
    end
end


return Renderer