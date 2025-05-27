local BaseRederer   = require "engine.3D.renderers.baseRenderer"
local CameraFrustum = require "engine.misc.cameraFrustum"
local lg            = love.graphics

local frustum = CameraFrustum()

--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2): ForwardRenderer
local ForwardRenderer = BaseRederer:extend("ForwardRenderer")


function ForwardRenderer:new(screensize)
    BaseRederer.new(self, screensize)
end


function ForwardRenderer:renderMeshes(camera)
    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.clear()

    frustum:updatePlanes(camera.viewProjectionMatrix)

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
        if frustum:testIntersection(config.meshPart.aabb, config.worldMatrix) then
            config.material:setRenderPass("depth")

            config.material.shader:use()
            config.material.shader:sendMeshConfigUniforms(config)
            config.material.shader:sendCommonUniforms()
            config.material.shader:sendRendererUniforms(self)
            config.material.shader:sendCameraUniforms(camera)

            config.material:apply()
            lg.draw(config.meshPart.buffer)
        end
    end


    ---------------
    -- Rendering --
    ---------------

    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add", "alphamultiply")

    for c, config in ipairs(self.meshParts) do
        local material = config.material
        local shader = material.shader

        if frustum:testIntersection(config.meshPart.aabb, config.worldMatrix) then
            material:setRenderPass("forward")

            for l, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                material:setLight(light)

                shader:use()
                shader:sendCommonUniforms()
                shader:sendRendererUniforms(self) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                shader:sendCameraUniforms(camera)
                shader:sendMeshConfigUniforms(config)


                material:apply()
                config.meshPart:draw()

                ::continue::
            end
        end
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer