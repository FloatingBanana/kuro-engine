local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"

local hdrShader = [[
    #pragma language glsl3

    uniform vec3  u_filter;
    uniform float u_contrast;
    uniform float u_brightness;
    uniform float u_exposure;
    uniform float u_saturation;

    #define CLAMP(v) clamp(v, 0, 1)

    float Luminance(vec3 color);
    #pragma include "engine/shaders/incl_utils.glsl"

    vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
        vec3 pixel = texture(tex, texcoords).rgb;

        // Color filter
        pixel *= u_filter;

        // Contrast
        pixel = CLAMP(((pixel - 0.5) * u_contrast) + 0.5);

        // Brightness
        pixel = CLAMP(pixel + u_brightness);

        // Exposure
        pixel = CLAMP(pixel * u_exposure);

        // Saturation
        vec3 grayscale = vec3(Luminance(pixel));
        pixel = CLAMP(mix(grayscale, pixel, u_saturation));

        // Gamma correction
        // pixel = pow(pixel, vec3(1.0/gamma));

        return vec4(pixel, 1.0);
    }
]]


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
local ColorCorrection = BaseEffect:extend()


function ColorCorrection:new(screenSize, contrast, brightness, exposure, saturation, colorFilter)
    self.canvas = love.graphics.newCanvas(screenSize.width, screenSize.height)
    self.shader = Utils.newPreProcessedShader(hdrShader)

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


function ColorCorrection:onPostRender(renderer, canvas, camera)
    love.graphics.setCanvas(self.canvas)
    love.graphics.setShader(self.shader)

    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

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