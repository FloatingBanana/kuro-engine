local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils      = require "engine.misc.utils"

-- http://john-chapman-graphics.blogspot.com/2013/01/per-object-motion-blur.html

local motionBlurShader = Utils.newPreProcessedShader([[
    #pragma language glsl3
    #pragma include "engine/shaders/incl_utils.glsl"

    uniform sampler2D u_velocityBuffer;
    uniform float u_velocityScale;

    vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
        vec2 pixelSize = 1.0 / textureSize(tex, 0);

        vec2 velocity = DecodeVelocity(texture(u_velocityBuffer, texcoords).xy) * u_velocityScale;
        float speed = length(velocity / pixelSize);
        int nSamples = clamp(int(speed), 1, 10);

        vec3 pixelColor = texture(tex, texcoords).rgb;

        for (int i=1; i < nSamples; i++) {
            vec2 offset = texcoords + velocity * (float(i) / float(nSamples - 1) - 0.5);

            pixelColor += texture(tex, offset).rgb;
        }

        return vec4(pixelColor / nSamples, 1.0);
    }
]])

--- @class MotionBlur: BasePostProcessingEffect
---
--- @field private blurCanvas love.Canvas
--- @field public amount number
---
--- @overload fun(screenSize: Vector2, amount: number): MotionBlur
local MotionBlur = BaseEffect:extend("MotionBlur")


function MotionBlur:new(screenSize, amount)
    self.blurCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height)
    self.amount = amount
end


function MotionBlur:onPostRender(renderer, canvas, camera)
    love.graphics.setCanvas(self.blurCanvas)
    love.graphics.setShader(motionBlurShader)

    motionBlurShader:send("u_velocityBuffer", renderer.velocityBuffer)
    motionBlurShader:send("u_velocityScale", (1 - love.timer.getAverageDelta()) * self.amount)
    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return self.blurCanvas
end


return MotionBlur