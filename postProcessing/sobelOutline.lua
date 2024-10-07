local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local ShaderEffect = require "engine.misc.shaderEffect"

local sobelShader = ShaderEffect("engine/shaders/postprocessing/sobelOutline.frag")

--- @class SobelOutline: BasePostProcessingEffect
---
--- @field thickness number
--- @field color number[]
--- @field private outlineCanvas love.Canvas
---
--- @overload fun(screenSize: Vector2, thickness: number, color: number[]): SobelOutline
local SobelOutline = BaseEffect:extend("SobelOutline")


function SobelOutline:new(screenSize, thickness, color)
    self.outlineCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height, {format = "rgba8"})
    self.outlineCanvas:setFilter("linear", "linear")

    self.thickness = thickness
    self.color = color
end


function SobelOutline:onPostRender(renderer, canvas)
    sobelShader:use()
    sobelShader:sendRendererUniforms(renderer)
    sobelShader:sendUniform("u_thickness", self.thickness)
    sobelShader:sendUniform("u_outlineColor", self.color)

    love.graphics.setCanvas(self.outlineCanvas)
    love.graphics.draw(canvas)

    return self.outlineCanvas
end


return SobelOutline