local BaseRederer = require "engine.3D.renderers.baseRenderer"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local prePassShader = Utils.newPreProcessedShader("engine/shaders/3D/forwardRendering/prepass.glsl")


--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): ForwardRenderer
local ForwardRenderer = BaseRederer:extend("ForwardRenderer")


function ForwardRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)
end


--- @param camera Camera3D
function ForwardRenderer:renderMeshes(camera)
    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshParts)
    end

    lg.setCanvas({self.velocityBuffer, depthstencil = self.depthCanvas})
    lg.clear()

    --------------------
    -- Depth pre-pass --
    --------------------
    -- Calculating depth values beforehand so they don't
    -- get in the way when doing the multi-pass lighting.
    -- Kinda sucks that we have to render everything again
    -- but hey, at least we have depth info for lighting
    -- effects (like SSAO) so it's not that bad.

    lg.setDepthMode("lequal", true)
    lg.setMeshCullMode("back")
    lg.setBlendMode("replace")
    lg.setShader(prePassShader)
    self:sendCommonRendererBuffers(prePassShader, camera)

    for i, config in ipairs(self.meshParts) do
        self:sendCommonMeshBuffers(prePassShader, config)
        lg.draw(config.meshPart.buffer)
    end


    lg.setShader()
    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self, camera)
    end

    ---------------
    -- Rendering --
    ---------------

    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.clear(true, false, false)
    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add", "premultiplied")

    while self.meshParts:peek() do
        local config = self.meshParts:pop() --[[@as MeshPartConfig]]
        local mat = config.meshPart.material --[[@as ForwardMaterial]]

        if config.ignoreLighting then
            self:sendCommonRendererBuffers(mat.shader, camera)
            self:sendCommonMeshBuffers(mat.shader, config)
            config.meshPart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                mat:setLightType(getmetatable(light))
                light:applyLighting(mat.shader)
                self:sendCommonRendererBuffers(mat.shader, camera) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                self:sendCommonMeshBuffers(mat.shader, config)

                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, mat.shader)
                end

                config.meshPart:draw()
                ::continue::
            end
        end

        self:recycleConfigTable(config)
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer