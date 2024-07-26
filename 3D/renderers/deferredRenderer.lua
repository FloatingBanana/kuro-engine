local PointLight       = require "engine.3D.lights.pointLight"
local Model            = require "engine.3D.model.model"
local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local Utils            = require "engine.misc.utils"
local ShaderEffect     = require "engine.misc.shaderEffect"
local lg               = love.graphics


local volume = Model("engine/3D/renderers/lightvolume.fbx", {triangulate = true, optimizeGraph = true, removeUnusedMaterials = true}).meshes.Sphere.parts[1]


---@alias GBuffer {uniform: string, buffer: love.Canvas}[]

--- @class DeferredRenderer: BaseRenderer
---
--- @field private dummySquare love.Mesh
--- @field public gbuffer GBuffer
--- @field public shader ShaderEffect
---
--- @overload fun(screensize: Vector2, camera: Camera3D, gbuffer: GBuffer, shader: ShaderEffect): DeferredRenderer
local DeferredRenderer = BaseRederer:extend("DeferredRenderer")


function DeferredRenderer:new(screensize, camera, gbuffer, shader)
    BaseRederer.new(self, screensize, camera)

    self.dummySquare = Utils.newSquareMesh(screensize)
    self.gbuffer = gbuffer
    self.shader = shader
end


function DeferredRenderer:renderMeshes()
    --------------
    -- G-Buffer --
    --------------

    --* TODO: cache this
    local mrt = {depthstencil = self.depthCanvas}
    for i, bufferPart in ipairs(self.gbuffer) do
        mrt[i] = bufferPart.buffer
    end

    lg.setCanvas(mrt)
    lg.clear()

    self.shader:define("CURRENT_RENDER_PASS", "RENDER_PASS_DEFERRED")
    self.shader:use()

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")

    for i, config in ipairs(self.meshParts) do
        self.shader:sendCommonUniforms()
        self.shader:sendRendererUniforms(self)
        self.shader:sendMeshConfigUniforms(config)

        config.material:apply(self.shader)
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

    self.shader:define("CURRENT_RENDER_PASS", "RENDER_PASS_DEFERRED_LIGHTPASS")

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        self.shader:define("CURRENT_LIGHT_TYPE", light.typeDefinition)

        self.shader:sendCommonUniforms()
        self.shader:sendRendererUniforms(self)

        for b, bufferPart in ipairs(self.gbuffer) do
            self.shader:trySendUniform(bufferPart.uniform, bufferPart.buffer)
        end

        light:generateShadowMap(self.meshParts)
        light:sendLightData(self.shader)

        for j, effect in ipairs(self.postProcessingEffects) do
            effect:onLightRender(light, self.shader.shader)
        end

        self.shader:use()

        if light:is(PointLight) then ---@cast light PointLight
            local transform = Matrix.CreateScale(Vector3(light:getLightRadius())) * Matrix.CreateTranslation(light.position) * self.camera.viewProjectionMatrix

            self.shader:sendUniform("u_volumeTransform", transform)
            volume:draw()
        else
            self.shader:sendUniform("u_volumeTransform", Matrix.CreateOrthographicOffCenter(0, WIDTH, HEIGHT, 0, 0, 1))
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