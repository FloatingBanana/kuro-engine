local PointLight       = require "engine.3D.lights.pointLight"
local Model            = require "engine.3D.model.model"
local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local Utils            = require "engine.misc.utils"
local ShaderEffect     = require "engine.misc.shaderEffect"
local lg               = love.graphics


local volume = Model("engine/3D/renderers/lightvolume.fbx", {triangulate = true, optimizeGraph = true, removeUnusedMaterials = true}).meshes.Sphere.parts[1]
local lightShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/deferred/lightPass.glsl", {"DEFERRED_LIGHTPASS"})
local gBufferShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/deferred/gbuffer.glsl", {"DEFERRED"})


--- @alias GBuffer {position: love.Canvas, normal: love.Canvas, albedoSpec: love.Canvas}

--- @class DeferredRenderer: BaseRenderer
---
--- @field private dummySquare love.Mesh
--- @field public gbuffer GBuffer
---
--- @overload fun(screensize: Vector2, camera: Camera3D): DeferredRenderer
local DeferredRenderer = BaseRederer:extend("DeferredRenderer")


function DeferredRenderer:new(screensize, camera)
    BaseRederer.new(self, screensize, camera)

    self.dummySquare = Utils.newSquareMesh(screensize)

    self.gbuffer = {
        normal     = lg.newCanvas(screensize.width, screensize.height, {format = "rg8"}),
        albedoSpec = lg.newCanvas(screensize.width, screensize.height)
    }
end


function DeferredRenderer:renderMeshes()
    --------------
    -- G-Buffer --
    --------------

    lg.setCanvas({self.gbuffer.normal, self.gbuffer.albedoSpec, depthstencil = self.depthCanvas})
    lg.clear()

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")

    for i, config in ipairs(self.meshParts) do
        gBufferShader:sendCommonUniforms()
        gBufferShader:sendRendererUniforms(self)
        gBufferShader:sendMeshConfigUniforms(config)

        gBufferShader:use()
        config.material:apply(gBufferShader)
        config.meshPart:draw()
    end


    ----------------
    -- Light pass --
    ----------------

    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("front")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.postProcessingEffects) do
        effect:onPreRender(self)
    end

    lg.setBlendMode("add", "alphamultiply")
    lg.setCanvas(self.resultCanvas)
    lg.clear()

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        lightShader:define("CURRENT_LIGHT_TYPE", light.typeDefinition)

        lightShader:sendCommonUniforms()
        lightShader:sendRendererUniforms(self)

        light:generateShadowMap(self.meshParts)
        light:sendLightData(lightShader)

        for j, effect in ipairs(self.postProcessingEffects) do
            effect:onLightRender(light, lightShader.shader)
        end

        lightShader:use()

        if light:is(PointLight) then ---@cast light PointLight
            local transform = Matrix.CreateScale(Vector3(light:getLightRadius())) * Matrix.CreateTranslation(light.position) * self.camera.viewProjectionMatrix

            lightShader:sendUniform("u_volumeTransform", transform)
            volume:draw()
        else
            lightShader:sendUniform("u_volumeTransform", Matrix.CreateOrthographicOffCenter(0, WIDTH, HEIGHT, 0, 0, 1))
            lg.draw(self.dummySquare)
        end

        ::continue::
    end

    while self.meshParts:peek() do
        self:recycleConfigTable(self.meshParts:pop())
    end

    lg.setShader()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")
end


return DeferredRenderer