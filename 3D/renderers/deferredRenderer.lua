local DirectionalLight = require "engine.3D.lights.directionalLight"
local SpotLight        = require "engine.3D.lights.spotLight"
local PointLight       = require "engine.3D.lights.pointLight"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local Model            = require "engine.3D.model.model"
local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local Matrix           = require "engine.math.matrix"
local Vector3          = require "engine.math.vector3"
local Utils            = require "engine.misc.utils"
local lg               = love.graphics


local black = {0,0,0,0}
local volume = Model("engine/3D/renderers/lightvolume.fbx", {flags = {"calc tangent space", "triangulate"}}).meshes.Sphere.parts[1]
local code = love.filesystem.read("engine/shaders/3D/deferred/lightPass.glsl")

local lightPassShaders = {
    [AmbientLight]     = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_AMBIENT"}),
    [DirectionalLight] = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_DIRECTIONAL"}),
    [SpotLight]        = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_SPOT"}),
    [PointLight]       = Utils.newPreProcessedShader(code, {"LIGHT_TYPE_POINT"}),
}


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
        normal     = lg.newCanvas(screensize.width, screensize.height, {format = "rg8"}),
        albedoSpec = lg.newCanvas(screensize.width, screensize.height)
    }
end


function DeferredRenderer:renderMeshes(camera)
    --------------
    -- G-Buffer --
    --------------

    lg.setCanvas({self.gbuffer.normal, self.gbuffer.albedoSpec, self.velocityBuffer, depthstencil = self.depthCanvas})
    lg.clear(black, black, black, black) ---@diagnostic disable-line param-type-mismatch

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")

    for id, config in pairs(self.meshes) do
        if config.onDraw then
            config.onDraw(id, config)
        end

        for i, part in ipairs(config.mesh.parts) do
            self:sendCommonRendererBuffers(part.material.shader, camera)
            self:sendCommonMeshBuffers(part.material.shader, id)
            part:draw()
        end
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
        self:sendCommonRendererBuffers(lightShader, camera)

        light:generateShadowMap(self.meshes)
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


---@param shader love.Shader
---@param camera Camera3D
function DeferredRenderer:sendCommonRendererBuffers(shader, camera)
    BaseRederer.sendCommonRendererBuffers(self, shader, camera)

	Utils.trySendUniform(shader, "uGNormal", self.gbuffer.normal)
	Utils.trySendUniform(shader, "uGAlbedoSpecular", self.gbuffer.albedoSpec)
end


return DeferredRenderer