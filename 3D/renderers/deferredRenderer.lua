local BaseRederer   = require "engine.3D.renderers.baseRenderer"
local Matrix4       = require "engine.math.matrix4"
local Vector3       = require "engine.math.vector3"
local CameraFrustum = require "engine.misc.cameraFrustum"
local Utils         = require "engine.misc.utils"
local Vector2       = require "engine.math.vector2"
local lg            = love.graphics


local sphereVolume = Utils.newSphereMesh(Vector3(1), 32, 32)
local coneVolume = Utils.newConeMesh(Vector3(1), 32)
local squareVolume = Utils.newSquareMesh(Vector2(1))
local frustum = CameraFrustum()

---@alias GBuffer {uniform: string, buffer: love.Canvas}[]

--- @class DeferredRenderer: BaseRenderer
---
--- @field public gbuffer love.Canvas[]
--- @field public lightPassMaterial BaseMaterial
---
--- @overload fun(screensize: Vector2, lightPassMaterial: BaseMaterial): DeferredRenderer
local DeferredRenderer = BaseRederer:extend("DeferredRenderer")


function DeferredRenderer:new(screensize, lightPassMaterial)
    BaseRederer.new(self, screensize)

    self.lightPassMaterial = lightPassMaterial
    self.gbuffer = {}

    for i, pixelFormat in ipairs(lightPassMaterial.GBufferLayout) do
        self.gbuffer[i] = love.graphics.newCanvas(screensize.width, screensize.height, {format = pixelFormat})
    end
end


function DeferredRenderer:renderMeshes(camera)
    --------------
    -- G-Buffer --
    --------------

    --* TODO: cache this
    lg.setCanvas {depthstencil = self.depthCanvas, unpack(self.gbuffer)}
    lg.clear()

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace", "premultiplied")
    lg.setMeshCullMode("back")

    frustum:updatePlanes(camera.viewPerspectiveMatrix)
    self.lightPassMaterial:setRenderPass("gbuffer")
    self.lightPassMaterial.shader:sendCommonUniforms()
    self.lightPassMaterial.shader:sendRendererUniforms(self)
    self.lightPassMaterial.shader:sendCameraUniforms(camera)
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
        effect:onPreRender(self, camera)
    end

    lg.setBlendMode("add", "alphamultiply")
    lg.setCanvas(self.resultCanvas)
    lg.clear()

    self.lightPassMaterial:setRenderPass("lightpass")

    for i, light in ipairs(self.lights) do
        if not light.enabled then goto continue end

        local volumeMatrix = nil
        local volumeMesh = nil

        if Utils.isType(light, "PointLight") then ---@cast light PointLight
            volumeMatrix = Matrix4.CreateScale(Vector3(light.farPlane)):multiply(Matrix4.CreateTranslation(light.position)):multiply(camera.viewPerspectiveMatrix)
            volumeMesh = sphereVolume

        elseif Utils.isType(light, "SpotLight") then ---@cast light SpotLight
            local coneSize = light.farPlane * math.cos(light.outerAngle)
            volumeMatrix = Matrix4.CreateScale(Vector3(coneSize, coneSize, light.farPlane)):multiply(Matrix4.CreateWorld(light.position, light.direction, Vector3(0,1,0))):multiply(camera.viewPerspectiveMatrix)
            volumeMesh = coneVolume
        else
            volumeMatrix = Matrix4.CreateOrthographicOffCenter(0, 1, 1, 0, 0, 1)
            volumeMesh = squareVolume
        end

        self.lightPassMaterial:setLight(light)
        self.lightPassMaterial.shader:use()
        self.lightPassMaterial.shader:sendCommonUniforms()
        self.lightPassMaterial.shader:sendRendererUniforms(self)
        self.lightPassMaterial.shader:sendCameraUniforms(camera)
        self.lightPassMaterial.shader:trySendUniform("u_ambientOcclusion", self.ambientOcclusion)
        self.lightPassMaterial:apply()

        self.lightPassMaterial.shader:trySendUniform("u_deferredInput", unpack(self.gbuffer))
        self.lightPassMaterial.shader:sendUniform("uWorldMatrix", "column", volumeMatrix)

        lg.draw(volumeMesh)

        ::continue::
    end

    lg.setShader()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")
end


return DeferredRenderer