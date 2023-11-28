local DirectionalLight = require "engine.3D.lights.directionalLight"
local SpotLight = require "engine.3D.lights.spotLight"
local PointLight = require "engine.3D.lights.pointLight"
local AmbientLight = require "engine.3D.lights.ambientLight"
local Model = require "engine.3D.model.model"
local BaseRederer = require "engine.3D.renderers.baseRenderer"
local Matrix      = require "engine.math.matrix"
local Vector3     = require "engine.math.vector3"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local black = Color.BLACK
local volume = Model("engine/3D/renderers/lightvolume.fbx", {flags = {"calc tangent space", "triangulate"}}).meshes.Sphere.parts[1]
local code = love.filesystem.read("engine/shaders/3D/deferred/lightPass.glsl")

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

        if settings.animator then
            mat.boneMatrices = settings.animator.finalMatrices
        end

        part:draw()
    end


    ----------------
    -- Light pass --
    ----------------

    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("front")
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

        if light:is(PointLight) then ---@cast light PointLight
            local transform = Matrix.CreateScale(Vector3(light:getLightRadius())) * Matrix.CreateTranslation(light.position) * camera.viewProjectionMatrix
            lightShader:send("u_volumeTransform", "column", transform:toFlatTable())
            lg.draw(volume.buffer)
        else
            lightShader:send("u_volumeTransform", "column", Matrix.CreateOrthographicOffCenter(0, WIDTH, HEIGHT, 0, 0, 1):toFlatTable())
            lg.draw(self.dummySquare)
        end
        
        ::continue::
    end
    
    lg.setShader()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")
end


return DeferredRenderer