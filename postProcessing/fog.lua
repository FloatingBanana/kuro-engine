local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"

-- https://vicrucann.github.io/tutorials/osg-shader-fog/


--- @class Fog: BasePostProcessingEffect
---
--- @field private hdrCanvas love.Canvas
--- @field private shader love.Shader
--- @field public min number
--- @field public max number
--- @field public color table
---
--- @overload fun(screenSize: Vector2, min: number, max: number, color: table): Fog
local Fog = BaseEffect:extend("Fog")


function Fog:new(screenSize, min, max, color)
    self.fogCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rg11b10f"})
    self.shader = Utils.newPreProcessedShader("engine/shaders/postprocessing/fog.frag")

    self.min = min
    self.max = max
    self.color = color

    self:setTreshold(min, max)
    self:setColor(color)
end


function Fog:onPostRender(renderer, canvas, camera)
    love.graphics.setCanvas(self.fogCanvas)
    love.graphics.setShader(self.shader)

    renderer:sendCommonRendererBuffers(self.shader, camera)
    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return self.fogCanvas
end


--- @param min number
--- @param max number
function Fog:setTreshold(min, max)
    self.shader:send("u_minMaxDistance", {min, max})
    self.min = min
    self.max = max
end


--- @param color table
function Fog:setColor(color)
    self.shader:send("u_fogColor", color)
    self.color = color
end


return Fog