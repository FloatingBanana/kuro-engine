local DirectionalLight = require "engine.3DRenderer.lights.directionalLight"
local SpotLight = require "engine.3DRenderer.lights.spotLight"
local PointLight = require "engine.3DRenderer.lights.pointLight"
local AmbientLight = require "engine.3DRenderer.lights.ambientLight"
local BaseRederer = require "engine.3DRenderer.renderers.baseRenderer"

local black = Color.BLACK
local code = lfs.read("engine/shaders/3D/deferred/lightPass.frag")


local lightPassShaders = {
    [AmbientLight]     = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_AMBIENT"}),
    [DirectionalLight] = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_DIRECTIONAL"}),
    [SpotLight]        = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_SPOT"}),
    [PointLight]       = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_POINT"}),
}


local function sendUniformIfExist(shader, uniform, value)
    if shader:hasUniform(uniform) then
        shader:send(uniform, value)
    end
end


--- @alias GBuffer {position: love.Canvas, normal: love.Canvas, albedoSpec: love.Canvas}

--- @class DeferredRenderer: BaseRenderer
---
--- @field private dummySquare love.Mesh
--- @field public gbuffer GBuffer
---
--- @overload fun(screensize: Vector2, posProcessingEffects: BasePostProcessingEffect[]): DeferredRenderer
local DeferredRenderer = BaseRederer:extend()


function DeferredRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)

    self.dummySquare = Utils.newSquareMesh(screensize)

    self.gbuffer = {
        position   = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"}),
        normal     = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"}),
        albedoSpec = lg.newCanvas(screensize.width, screensize.height)
    }
end


function DeferredRenderer:renderMeshes(camera)
    --------------
    -- G-Buffer --
    --------------

    lg.setCanvas({self.gbuffer.position, self.gbuffer.normal, self.gbuffer.albedoSpec, self.velocityBuffer, depthstencil = self.depthCanvas})
    lg.clear(black, black, black, black)

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")

    for part, settings in pairs(self.meshparts) do
        if settings.onDraw then
            settings.onDraw(part, settings)
        end
        local mat = part.material

        mat.worldMatrix = settings.worldMatrix
        mat.viewProjectionMatrix = camera.viewProjectionMatrix
        mat.previousTransformation = self.previousTransformations[part]
        part:draw()
    end


    ----------------
    -- Light pass --
    ----------------

    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self, camera)
    end

    lg.setBlendMode("add", "alphamultiply")
    lg.setCanvas(self.resultCanvas)
    lg.clear()

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        local lightShader = lightPassShaders[getmetatable(light)]

        sendUniformIfExist(lightShader, "u_viewPosition", camera.position:toFlatTable())
        sendUniformIfExist(lightShader, "u_gPosition",    self.gbuffer.position)
        sendUniformIfExist(lightShader, "u_gNormal",      self.gbuffer.normal)
        sendUniformIfExist(lightShader, "u_gAlbedoSpec",  self.gbuffer.albedoSpec)

        light:generateShadowMap(self.meshparts)
        light:applyLighting(lightShader)

        for j, effect in ipairs(self.ppeffects) do
            effect:onLightRender(light, lightShader)
        end

        lg.setShader(lightShader)
        lg.draw(self.dummySquare)
        
        ::continue::
    end

    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return DeferredRenderer