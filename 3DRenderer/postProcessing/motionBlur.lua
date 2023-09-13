local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"
local Matrix     = require "engine.math.matrix"

local motionBlurShader = lg.newShader [[
    #pragma language glsl3

    uniform sampler2D u_depthBuffer;
    uniform mat4 u_invViewProj;
    uniform mat4 u_prevViewProj;
    uniform int u_numSamples;

    vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
        float depth = texture(u_depthBuffer, texcoords).r;
        vec3 clipPos = vec3(texcoords.x, 1.0 - texcoords.y, depth) * 2.0 - 1.0;

        vec4 worldPos = u_invViewProj * vec4(clipPos, 1.0);
        worldPos.xyz /= worldPos.w;

        vec4 prevClipPos = u_prevViewProj * vec4(worldPos.xyz, 1.0);
        prevClipPos.xyz /= prevClipPos.w;
        
        vec2 velocity = (clipPos.xy - prevClipPos.xy) / 20.0;

        vec3 pixelColor = texture(tex, texcoords).rgb;
        vec2 sampleUV = texcoords + velocity;

        for (int i=1; i < u_numSamples; i++, sampleUV += velocity) {
            pixelColor += texture(tex, sampleUV).rgb;
        }

        return vec4(pixelColor / u_numSamples, 1.0);
    }
]]

--- @class MotionBlur: BasePostProcessingEffect
---
--- @field private blurCanvas love.Canvas
--- @field private prevViewProj Matrix
--- @field public sampleCount integer
---
--- @overload fun(screenSize: Vector2, sampleCount: integer): MotionBlur
local MotionBlur = BaseEffect:extend()


function MotionBlur:new(screenSize, sampleCount)
    self.blurCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "rgba16f"})
    self.prevViewProj = Matrix.Identity()
    self.sampleCount = sampleCount
end


function MotionBlur:onPostRender(device, canvas, camera)
    local viewProj = camera.viewProjectionMatrix --- @type Matrix
    local invViewProj = viewProj.inverse
    local prevViewProj = self.prevViewProj
    self.prevViewProj = viewProj

    lg.setCanvas(self.blurCanvas)
    lg.setShader(motionBlurShader)

    motionBlurShader:send("u_depthBuffer", device.depthCanvas)
    motionBlurShader:send("u_invViewProj", "column", invViewProj:toFlatTable())
    motionBlurShader:send("u_prevViewProj", "column", prevViewProj:toFlatTable())
    motionBlurShader:send("u_numSamples", self.sampleCount)
    lg.draw(canvas)

    lg.setCanvas()
    lg.setShader()

    return self.blurCanvas
end


return MotionBlur