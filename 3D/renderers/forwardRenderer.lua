local BaseRederer      = require "engine.3D.renderers.baseRenderer"
local ShaderEffect     = require "engine.misc.shaderEffect"
local DirectionalLight = require "engine.3D.lights.directionalLight"
local SpotLight        = require "engine.3D.lights.spotLight"
local PointLight       = require "engine.3D.lights.pointLight"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local lg               = love.graphics


local prePassShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", {"FORWARD_PREPASS"})
local defaultShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/forwardRendering/forwardRendering.frag")


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

    prePassShader:use()
    self:sendCommonRendererBuffers(prePassShader.shader, camera)

    for i, config in ipairs(self.meshParts) do
        self:sendCommonMeshBuffers(prePassShader.shader, config)
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

        if config.ignoreLighting then
            self:sendCommonRendererBuffers(defaultShader.shader, camera)
            self:sendCommonMeshBuffers(defaultShader.shader, config)

            defaultShader:use()
            config.meshPart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                local lightTypeDef =
                    light:is(AmbientLight)     and "LIGHT_TYPE_AMBIENT"     or
                    light:is(DirectionalLight) and "LIGHT_TYPE_DIRECTIONAL" or
                    light:is(SpotLight)        and "LIGHT_TYPE_SPOT"        or
                    light:is(PointLight)       and "LIGHT_TYPE_POINT"       or nil


                defaultShader:define(lightTypeDef)

                light:applyLighting(defaultShader.shader)
                self:sendCommonRendererBuffers(defaultShader.shader, camera) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                self:sendCommonMeshBuffers(defaultShader.shader, config)
                
                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, defaultShader.shader)
                end
                
                defaultShader:use()
                config.material:apply(defaultShader)
                config.meshPart:draw()

                defaultShader:undefine(lightTypeDef)
                ::continue::
            end
        end

        self:recycleConfigTable(config)
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer