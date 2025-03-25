local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"

--- @class ColorCorrection: BasePostProcessingEffect
---
--- @field private canvas love.Canvas
--- @field private shader love.Shader
--- @field public contrast number
--- @field public brightness number
--- @field public exposure number
--- @field public saturation number
--- @field public colorFilter table
---
--- @overload fun(screenSize: Vector2, contrast: number, brightness: number, exposure: number, saturation: number, colorFilter: table): ColorCorrection
local ColorCorrection = BaseEffect:extend("ColorCorrection")


function ColorCorrection:new(screenSize, contrast, brightness, exposure, saturation, colorFilter)
    self.canvas = love.graphics.newCanvas(screenSize.width, screenSize.height)
    self.shader = Utils.newPreProcessedShader("engine/shaders/postprocessing/colorCorrection.frag")

    self.contrast = contrast
    self.brightness = brightness
    self.exposure = exposure
    self.saturation = saturation
    self.colorFilter = colorFilter

    self:setContrast(contrast)
    self:setBrightness(brightness)
    self:setExposure(exposure)
    self:setSaturation(saturation)
    self:setColorFilter(colorFilter)
end


function ColorCorrection:onPostRender(renderer, camera, canvas)
    love.graphics.setCanvas(self.canvas)
    love.graphics.setShader(self.shader)
    love.graphics.draw(canvas)

    return self.canvas
end


--- @param contrast number
function ColorCorrection:setContrast(contrast)
    self.shader:send("u_contrast", contrast)
    self.contrast = contrast
end


--- @param brightness number
function ColorCorrection:setBrightness(brightness)
    self.shader:send("u_brightness", brightness)
    self.brightness = brightness
end


--- @param exposure number
function ColorCorrection:setExposure(exposure)
    self.shader:send("u_exposure", exposure)
    self.exposure = exposure
end


--- @param saturation number
function ColorCorrection:setSaturation(saturation)
    self.shader:send("u_saturation", saturation)
    self.saturation = saturation
end


--- @param filter table
function ColorCorrection:setColorFilter(filter)
    self.shader:send("u_filter", filter)
    self.colorFilter = filter
end


return ColorCorrection