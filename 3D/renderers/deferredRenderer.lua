local DirectionalLight = require "engine.3D.lights.directionalLight"
local SpotLight        = require "engine.3D.lights.spotLight"
local PointLight       = require "engine.3D.lights.pointLight"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local Model            = require "engine.3D.model.model"
local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local Utils            = require "engine.misc.utils"
local ShaderEffect     = require "engine.misc.shaderEffect"
local lg               = love.graphics


local volume = Model("engine/3D/renderers/lightvolume.fbx", {triangulate = true}).meshes.Sphere.parts[1]
local lightShader = ShaderEffect("engine/shaders/3D/deferred/lightPass.glsl")
local gBufferShader = ShaderEffect("engine/shaders/3D/deferred/gbuffer.glsl")


--- @alias GBuffer {position: love.Canvas, normal: love.Canvas, albedoSpec: love.Canvas}

--- @class DeferredRenderer: BaseRenderer
---
--- @field private dummySquare love.Mesh
--- @field public gbuffer GBuffer
---
--- @overload fun(screensize: Vector2, posProcessingEffects: BasePostProcessingEffect[]): DeferredRenderer
local DeferredRenderer = BaseRederer:extend("DeferredRenderer")


function DeferredRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)

    self.dummySquare = Utils.newSquareMesh(screensize)

    self.gbuffer = {
        normal     = lg.newCanvas(screensize.width, screensize.height, {format = "rg8"}),
        albedoSpec = lg.newCanvas(screensize.width, screensize.height)
    }
end


function DeferredRenderer:renderMeshes(camera)
    --------------
    -- G-Buffer --
    --------------

    lg.setCanvas({self.gbuffer.normal, self.gbuffer.albedoSpec, self.velocityBuffer, depthstencil = self.depthCanvas})
    lg.clear()

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")

    for i, config in ipairs(self.meshParts) do
        self:sendCommonRendererBuffers(gBufferShader.shader, camera)
        self:sendCommonMeshBuffers(gBufferShader.shader, config)

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

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self, camera)
    end

    lg.setBlendMode("add", "alphamultiply")
    lg.setCanvas(self.resultCanvas)
    lg.clear()

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        local lightTypeDef =
            light:is(AmbientLight)     and "LIGHT_TYPE_AMBIENT"     or
            light:is(DirectionalLight) and "LIGHT_TYPE_DIRECTIONAL" or
            light:is(SpotLight)        and "LIGHT_TYPE_SPOT"        or
            light:is(PointLight)       and "LIGHT_TYPE_POINT"       or nil


        lightShader:define(lightTypeDef)
        self:sendCommonRendererBuffers(lightShader.shader, camera)

        light:generateShadowMap(self.meshParts)
        light:applyLighting(lightShader.shader)

        for j, effect in ipairs(self.ppeffects) do
            effect:onLightRender(light, lightShader.shader)
        end

        lightShader:use()

        if light:is(PointLight) then ---@cast light PointLight
            local transform = Matrix.CreateScale(Vector3(light:getLightRadius())) * Matrix.CreateTranslation(light.position) * camera.viewProjectionMatrix

            lightShader:sendUniform("u_volumeTransform", transform)
            volume:draw()
        else
            lightShader:sendUniform("u_volumeTransform", Matrix.CreateOrthographicOffCenter(0, WIDTH, HEIGHT, 0, 0, 1))
            lg.draw(self.dummySquare)
        end

        lightShader:undefine(lightTypeDef)
        ::continue::
    end

    while self.meshParts:peek() do
        self:recycleConfigTable(self.meshParts:pop())
    end

    lg.setShader()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")
end


---@param shader love.Shader
---@param camera Camera3D
function DeferredRenderer:sendCommonRendererBuffers(shader, camera)
    BaseRederer.sendCommonRendererBuffers(self, shader, camera)

	Utils.trySendUniform(shader, "uGNormal", self.gbuffer.normal)
	Utils.trySendUniform(shader, "uGAlbedoSpecular", self.gbuffer.albedoSpec)
end


return DeferredRenderer