local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"

local fxaaShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/fxaa.frag")

-- http://blog.simonrodriguez.fr/articles/2016/07/implementing_fxaa.html
-- https://github.com/kosua20/Rendu/blob/master/resources/common/shaders/screens/fxaa.frag


--- @class FXAA: BasePostProcessingEffect
---
--- @field private fxaaCanvas love.Canvas
--- @field private shader love.Shader
---
--- @overload fun(screenSize: Vector2): FXAA
local FXAA = BaseEffect:extend("FXAA")


function FXAA:new(screenSize)
    self.fxaaCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rg11b10f"})
    self.shader = fxaaShader

    self.fxaaCanvas:setFilter("linear", "linear")
end


function FXAA:onPostRender(renderer, canvas)
    love.graphics.setCanvas(self.fxaaCanvas)
    love.graphics.setShader(self.shader)

    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return self.fxaaCanvas
end


return FXAA