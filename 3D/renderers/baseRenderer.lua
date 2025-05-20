local Lume         = require "engine.3rdparty.lume"
local Matrix4      = require "engine.math.matrix4"
local Stack        = require "engine.collections.stack"
local ShaderEffect = require "engine.misc.shaderEffect"
local CubemapUtils = require "engine.misc.cubemapUtils"
local Object       = require "engine.3rdparty.classic.classic"
local tableclear   = require "table.clear"

local skyboxShader = ShaderEffect("engine/shaders/3D/skybox.glsl")
local configPool = Stack()

--- @alias MeshPartConfig {meshPart: MeshPart, material: BaseMaterial, castShadows: boolean, ignoreLighting: boolean, static: boolean, worldMatrix: Matrix4, animator: ModelAnimator?}

--- @class BaseRenderer: Object
---
--- @field public screensize Vector2
--- @field public resultCanvas love.Canvas
--- @field public depthCanvas love.Canvas
--- @field public skyBoxTexture love.Texture
--- @field public postProcessingEffects BasePostProcessingEffect[]
--- @field public lights BaseLight[]
--- @field protected meshParts Stack
---
--- @overload fun(screenSize: Vector2): BaseRenderer
local Renderer = Object:extend("BaseRenderer")

function Renderer:new(screensize)
    self.screensize = screensize
    self.postProcessingEffects = {}
    self.meshParts = Stack()
    self.lights = {}

    self.skyBoxTexture = nil

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
    config.worldMatrix = Matrix4.Identity()
    config.animator = nil

    self.meshParts:push(config)
    return config
end


---@param config MeshPartConfig
function Renderer:removeMeshPart(config)
    table.remove(self.meshParts, Lume.find(self.meshParts, config))

    config.animator = nil
    config.meshPart = nil
    config.material = nil
    config.worldMatrix = nil
    configPool:push(config)
end


function Renderer:clearMeshParts()
    while self.meshParts:peek() do
        local config = self.meshParts:pop()
        config.animator = nil
        config.meshPart = nil
        config.material = nil
        config.worldMatrix = nil
        configPool:push(config)
    end
end


---@param ... BaseLight
function Renderer:addLights(...)
    Lume.push(self.lights, ...)
end


---@param light BaseLight
function Renderer:removeLight(light)
    table.remove(self.lights, Lume.find(self.lights, light))
end


function Renderer:clearLights()
    tableclear(self.lights)
end


---@param ... BasePostProcessingEffect
function Renderer:addPostProcessingEffects(...)
    Lume.push(self.postProcessingEffects, ...)
end


---@param effect BasePostProcessingEffect
function Renderer:removePostProcessingEffect(effect)
    table.remove(self.postProcessingEffects, Lume.find(self.postProcessingEffects, effect))
end


---@param camera Camera3D
function Renderer:renderMeshes(camera)
    error("Not implemented")
end


---@private
---@param camera Camera3D
function Renderer:_renderSkyBox(camera)
    local view = camera.viewMatrix
    view.m41, view.m42, view.m43 = 0, 0, 0

    love.graphics.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("lequal", false)

    skyboxShader:use()
    skyboxShader:sendUniform("u_viewProj", "column", view:multiply(camera.perspectiveMatrix))
    skyboxShader:sendUniform("u_skyTex", self.skyBoxTexture)

    love.graphics.draw(CubemapUtils.cubeMesh)
end


---@param camera Camera3D
---@return love.Canvas
function Renderer:render(camera)
    love.graphics.push("all")

    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshParts)
    end

    self:renderMeshes(camera)

    if self.skyBoxTexture then
        self:_renderSkyBox(camera)
    end

    love.graphics.pop()
    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.postProcessingEffects) do
        result = effect:onPostRender(self, camera, result)
    end

    love.graphics.pop()
    return result
end

return Renderer