local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

local fxaaShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/fxaa.frag")

-- http://blog.simonrodriguez.fr/articles/2016/07/implementing_fxaa.html
-- https://github.com/kosua20/Rendu/blob/master/resources/common/shaders/screens/fxaa.frag


--- @class FXAA: BasePostProcessingEffect
---
--- @field private fxaaCanvas love.Canvas
--- @field private shader love.Shader
---
--- @overload fun(screenSize: Vector2): FXAA
local FXAA = BaseEffect:extend()


function FXAA:new(screenSize)
    self.fxaaCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "rgba16f"})
    self.shader = fxaaShader

    self.fxaaCanvas:setFilter("linear", "linear")
end


function FXAA:onPostRender(device, canvas, camera)
    lg.setCanvas(self.fxaaCanvas)
    lg.setShader(self.shader)

    lg.draw(canvas)

    lg.setCanvas()
    lg.setShader()

    return self.fxaaCanvas
end


return FXAA