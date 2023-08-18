local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

local hdrShader = [[
    uniform vec3  u_filter;
    uniform float u_contrast;
    uniform float u_brightness;
    uniform float u_exposure;
    uniform float u_saturation;

    #define CLAMP(v) clamp(v, 0, 1)

    const vec3 lumFactor = vec3(0.299, 0.587, 0.114);
    const float gamma = 2.2;

    vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
        vec3 pixel = Texel(texture, texcoords).rgb;

        // Color filter
        pixel *= u_filter;

        // Contrast
        pixel = CLAMP(((pixel - 0.5) * u_contrast) + 0.5);

        // Brightness
        pixel = CLAMP(pixel + u_brightness);

        // Exposure
        pixel = CLAMP(pixel * u_exposure);

        // Saturation
        vec3 grayscale = vec3(dot(pixel, lumFactor));
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
---
--- @overload fun(screenSize: Vector2, contrast: number, brightness: number, exposure: number, saturation: number, colorFilter: table): ColorCorrection
local ColorCorrection = BaseEffect:extend()


function ColorCorrection:new(screenSize, contrast, brightness, exposure, saturation, colorFilter)
    self.canvas = lg.newCanvas(screenSize.width, screenSize.height)
    self.shader = lg.newShader(hdrShader)

    self:setContrast(contrast)
    self:setBrightness(brightness)
    self:setExposure(exposure)
    self:setSaturation(saturation)
    self:setColorFilter(colorFilter)
end


function ColorCorrection:applyPostRender(device, canvas, view, projection)
    lg.setCanvas(self.canvas)
    lg.setShader(self.shader)

    lg.draw(canvas)

    lg.setCanvas()
    lg.setShader()

    return self.canvas
end


--- @param contrast number
function ColorCorrection:setContrast(contrast)
    self.shader:send("u_contrast", contrast)
end


--- @param brightness number
function ColorCorrection:setBrightness(brightness)
    self.shader:send("u_brightness", brightness)
end


--- @param exposure number
function ColorCorrection:setExposure(exposure)
    self.shader:send("u_exposure", exposure)
end


--- @param saturation number
function ColorCorrection:setSaturation(saturation)
    self.shader:send("u_saturation", saturation)
end


--- @param filter table
function ColorCorrection:setColorFilter(filter)
    self.shader:send("u_filter", filter)
end


return ColorCorrection