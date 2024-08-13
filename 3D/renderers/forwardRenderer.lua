local BaseRederer = require "engine.3D.renderers.baseRenderer"
local lg          = love.graphics

--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, camera: Camera3D): ForwardRenderer
local ForwardRenderer = BaseRederer:extend("ForwardRenderer")


function ForwardRenderer:new(screensize, camera)
    BaseRederer.new(self, screensize, camera)
end


function ForwardRenderer:renderMeshes()
    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshParts)
    end

    lg.setCanvas({depthstencil = self.depthCanvas})
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

    for i, config in ipairs(self.meshParts) do
        config.material.shader:define("CURRENT_RENDER_PASS", "RENDER_PASS_DEPTH_PREPASS")
        config.material.shader:undefine("CURRENT_LIGHT_TYPE")

        config.material.shader:use()
        config.material.shader:sendMeshConfigUniforms(config)
        config.material.shader:sendCommonUniforms()
        config.material.shader:sendRendererUniforms(self)

        config.material:apply()
        lg.draw(config.meshPart.buffer)
    end


    lg.setShader()
    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.postProcessingEffects) do
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
        local shader = config.material.shader

        shader:define("CURRENT_RENDER_PASS", "RENDER_PASS_FORWARD")

        if config.ignoreLighting then
            shader:define("CURRENT_LIGHT_TYPE", "LIGHT_TYPE_UNLIT")
            shader:use()

            shader:sendCommonUniforms()
            shader:sendRendererUniforms(self)
            shader:sendMeshConfigUniforms(config)

            config.material:apply(shader)
            config.meshPart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                shader:define("CURRENT_LIGHT_TYPE", light.typeDefinition)
                shader:use()

                light:sendLightData(shader)

                shader:trySendUniform("u_irradianceMap", self.irradianceMap)
                shader:trySendUniform("u_prefilteredEnvironmentMap", self.preFilteredEnvironment)

                shader:sendCommonUniforms()
                shader:sendRendererUniforms(self) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                shader:sendMeshConfigUniforms(config)

                for j, effect in ipairs(self.postProcessingEffects) do
                    effect:onLightRender(light, shader.shader)
                end

                config.material:apply(shader)
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