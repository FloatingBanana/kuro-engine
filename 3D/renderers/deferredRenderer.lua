local PointLight    = require "engine.3D.lights.pointLight"
local Model         = require "engine.3D.model.model"
local BaseRederer   = require "engine.3D.renderers.baseRenderer"
local Matrix        = require "engine.math.matrix"
local Vector3       = require "engine.math.vector3"
local CameraFrustum = require "engine.misc.cameraFrustum"
local Utils         = require "engine.misc.utils"
local lg            = love.graphics


local volume = Model("engine/3D/renderers/lightvolume.fbx", {triangulate = true, optimizeGraph = true, removeUnusedMaterials = true}).meshes.Sphere.parts[1]
local frustum = CameraFrustum()

---@alias GBuffer {uniform: string, buffer: love.Canvas}[]

--- @class DeferredRenderer: BaseRenderer
---
--- @field private dummySquare love.Mesh
--- @field public gbuffer love.Canvas[]
--- @field public lightPassMaterial BaseMaterial
---
--- @overload fun(screensize: Vector2, camera: Camera3D, lightPassMaterial: BaseMaterial): DeferredRenderer
local DeferredRenderer = BaseRederer:extend("DeferredRenderer")


function DeferredRenderer:new(screensize, camera, lightPassMaterial)
    BaseRederer.new(self, screensize, camera)

    self.dummySquare = Utils.newSquareMesh(screensize)
    self.lightPassMaterial = lightPassMaterial
    self.gbuffer = {}

    for i, pixelFormat in ipairs(lightPassMaterial.GBufferLayout) do
        self.gbuffer[i] = love.graphics.newCanvas(screensize.width, screensize.height, {format = pixelFormat})
    end
end


function DeferredRenderer:renderMeshes()
    --------------
    -- G-Buffer --
    --------------

    --* TODO: cache this
    lg.setCanvas {depthstencil = self.depthCanvas, unpack(self.gbuffer)}
    lg.clear()

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace", "premultiplied")
    lg.setMeshCullMode("back")

    frustum:updatePlanes(self.camera.viewPerspectiveMatrix)
    self.lightPassMaterial:setRenderPass("gbuffer")
    self.lightPassMaterial.shader:sendCommonUniforms()
    self.lightPassMaterial.shader:sendRendererUniforms(self)
    self.lightPassMaterial.shader:use()

    for i, config in ipairs(self.meshParts) do
        if frustum:testIntersection(config.meshPart.aabb, config.worldMatrix) then
            self.lightPassMaterial.shader:sendMeshConfigUniforms(config)

            config.material:apply(self.lightPassMaterial.shader)
            config.meshPart:draw()
        end
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

    self.lightPassMaterial:setRenderPass("lightpass")

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        self.lightPassMaterial:setLight(light)

        for j, effect in ipairs(self.postProcessingEffects) do
            effect:onLightRender(light, self.lightPassMaterial.shader)
        end

        self.lightPassMaterial.shader:use()
        self.lightPassMaterial.shader:sendCommonUniforms()
        self.lightPassMaterial.shader:sendRendererUniforms(self)
        self.lightPassMaterial.shader:trySendUniform("u_ambientOcclusion", self.ambientOcclusion)
        self.lightPassMaterial.shader:trySendUniform("u_irradianceMap", self.irradianceMap)
        self.lightPassMaterial.shader:trySendUniform("u_environmentRadianceMap", self.environmentRadianceMap)

        for b, bufferPart in ipairs(self.gbuffer) do
            self.lightPassMaterial.shader:trySendUniform("u_deferredInput"..(b-1), bufferPart)
        end

        if light:is(PointLight) then ---@cast light PointLight
            local transform = Matrix.CreateScale(Vector3(light:getLightRadius())) * Matrix.CreateTranslation(light.position) * self.camera.viewPerspectiveMatrix

            self.lightPassMaterial.shader:sendUniform("u_volumeTransform", transform)
            volume:draw()
        else
            self.lightPassMaterial.shader:sendUniform("u_volumeTransform", Matrix.CreateOrthographicOffCenter(0, self.screensize.width, self.screensize.height, 0, 0, 1))
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