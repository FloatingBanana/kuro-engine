local Lume         = require "engine.3rdparty.lume"
local Vector3      = require "engine.math.vector3"
local Matrix       = require "engine.math.matrix"
local Stack        = require "engine.collections.stack"
local Utils        = require "engine.misc.utils"
local ShaderEffect = require "engine.misc.shaderEffect"
local CubemapUtils = require "engine.misc.cubemapUtils"
local Object       = require "engine.3rdparty.classic.classic"

local skyboxShader = ShaderEffect("engine/shaders/3D/skybox.glsl")
local configPool = Stack()

--- @alias MeshPartConfig {meshPart: MeshPart, material: BaseMaterial, castShadows: boolean, ignoreLighting: boolean, worldMatrix: Matrix, animator: ModelAnimator?}

--- @class BaseRenderer: Object
---
--- @field public resultCanvas love.Canvas
--- @field public depthCanvas love.Canvas
--- @field public velocityBuffer love.Canvas
--- @field public skyBoxTexture love.Texture
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


---@private
function Renderer:_renderSkyBox()
    local view = self.camera.viewMatrix:clone()
    view.m41, view.m42, view.m43 = 0, 0, 0

    love.graphics.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("lequal", false)

    skyboxShader:use()
    skyboxShader:sendUniform("u_viewProj", "column", view * self.camera.projectionMatrix)
    skyboxShader:sendUniform("u_skyTex", self.skyBoxTexture)

    love.graphics.draw(CubemapUtils.cubeMesh)
end


function Renderer:render()
    self.camera:updateMatrices()

    love.graphics.push("all")

    self:renderMeshes()
    self:_renderSkyBox()

    assert(#self.meshParts == 0, "Failed to consume all queued meshes")

    love.graphics.pop()
    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:onPostRender(self, result)
    end

    love.graphics.pop()
    love.graphics.draw(result)
end

return Renderer