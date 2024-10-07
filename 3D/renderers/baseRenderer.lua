local Lume         = require "engine.3rdparty.lume"
local Matrix       = require "engine.math.matrix"
local Stack        = require "engine.collections.stack"
local ShaderEffect = require "engine.misc.shaderEffect"
local CubemapUtils = require "engine.misc.cubemapUtils"
local Object       = require "engine.3rdparty.classic.classic"

local skyboxShader = ShaderEffect("engine/shaders/3D/skybox.glsl")
local configPool = Stack()

--- @alias MeshPartConfig {meshPart: MeshPart, material: BaseMaterial, castShadows: boolean, ignoreLighting: boolean, static: boolean, worldMatrix: Matrix, animator: ModelAnimator?}

--- @class BaseRenderer: Object
---
--- @field public screensize Vector2
--- @field public resultCanvas love.Canvas
--- @field public depthCanvas love.Canvas
--- @field public skyBoxTexture love.Texture
--- @field public irradianceMap love.Texture
--- @field public environmentRadianceMap love.Texture
--- @field public camera Camera3D
--- @field public postProcessingEffects BasePostProcessingEffect[]
--- @field protected meshParts Stack
--- @field protected lights BaseLight[]
---
--- @overload fun(screenSize: Vector2, camera: Camera3D): BaseRenderer
local Renderer = Object:extend("BaseRenderer")
Renderer.BRDF_LUT = CubemapUtils.getBRDF_LUT()

function Renderer:new(screensize, camera)
    self.screensize = screensize
    self.camera = camera
    self.postProcessingEffects = {}
    self.meshParts = Stack()
    self.lights = {}

    self.skyBoxTexture = nil
    self.irradianceMap = nil
    self.environmentRadianceMap = nil

    self.resultCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg11b10f"})
    self.depthCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "depth24stencil8", readable = true})
end

---@param meshPart MeshPart
---@return MeshPartConfig
function Renderer:pushMeshPart(meshPart)
    local config = configPool:pop() or {}

    config.material = meshPart.material
    config.meshPart = meshPart
    config.castShadows = true
    config.ignoreLighting = false
    config.static = false
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


---@param ... BasePostProcessingEffect
function Renderer:addPostProcessingEffects(...)
    Lume.push(self.postProcessingEffects, ...)
end


---@param effect BasePostProcessingEffect
function Renderer:removePostProcessingEffect(effect)
    table.remove(self.postProcessingEffects, Lume.find(self.postProcessingEffects, effect))
end


function Renderer:renderMeshes()
    error("Not implemented")
end


---@private
function Renderer:_renderSkyBox()
    local view = self.camera.viewMatrix
    view.m41, view.m42, view.m43 = 0, 0, 0

    love.graphics.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("lequal", false)

    skyboxShader:use()
    skyboxShader:sendUniform("u_viewProj", "column", view:multiply(self.camera.perspectiveMatrix))
    skyboxShader:sendUniform("u_skyTex", self.skyBoxTexture)

    love.graphics.draw(CubemapUtils.cubeMesh)
end


---@return love.Canvas
function Renderer:render()
    love.graphics.push("all")

    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshParts)
    end

    self:renderMeshes()

    if self.skyBoxTexture then
        self:_renderSkyBox()
    end

    assert(#self.meshParts == 0, "Failed to consume all queued meshes")

    love.graphics.pop()
    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.postProcessingEffects) do
        result = effect:onPostRender(self, result)
    end

    love.graphics.pop()
    return result
end

return Renderer