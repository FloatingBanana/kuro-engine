local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local ShaderEffect     = require "engine.misc.shaderEffect"
local lg               = love.graphics


local prePassShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", {"FORWARD_PREPASS"})
local defaultShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/forwardRendering/forwardRendering.frag")


--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, camera: Camera3D, postProcessingEffects: BasePostProcessingEffect[]): ForwardRenderer
local ForwardRenderer = BaseRederer:extend("ForwardRenderer")


function ForwardRenderer:new(screensize, camera, postProcessingEffects)
    BaseRederer.new(self, screensize, camera, postProcessingEffects)
end


function ForwardRenderer:renderMeshes()
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

    prePassShader:use()
    prePassShader:sendCommonUniforms()
    prePassShader:sendRendererUniforms(self)

    for i, config in ipairs(self.meshParts) do
        prePassShader:sendMeshConfigUniforms(config)
        config.material:apply(prePassShader)
        lg.draw(config.meshPart.buffer)
    end


    lg.setShader()
    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self)
    end

    ---------------
    -- Rendering --
    ---------------

    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.clear(true, false, false)
    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add", "alphamultiply")

    while self.meshParts:peek() do
        local config = self.meshParts:pop() --[[@as MeshPartConfig]]

        if config.ignoreLighting then
            defaultShader:define("CURRENT_LIGHT_TYPE", "LIGHT_TYPE_UNLIT")

            defaultShader:use()
            defaultShader:sendCommonUniforms()
            defaultShader:sendRendererUniforms(self)
            defaultShader:sendMeshConfigUniforms(config)

            config.material:apply(defaultShader)
            config.meshPart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                defaultShader:define("CURRENT_LIGHT_TYPE", light.typeDefinition)

                defaultShader:use()
                light:sendLightData(defaultShader)

                defaultShader:sendCommonUniforms()
                defaultShader:sendRendererUniforms(self) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                defaultShader:sendMeshConfigUniforms(config)

                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, defaultShader.shader)
                end

                config.material:apply(defaultShader)
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