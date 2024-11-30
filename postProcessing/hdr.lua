local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local ShaderEffect = require "engine.misc.shaderEffect"

local hdrShader = ShaderEffect [[
    #pragma language glsl3
    #pragma include "engine/shaders/include/incl_utils.glsl"

    uniform float u_exposure;
    
    vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
        vec3 hdrColor = texture(tex, texcoords).rgb;
        //vec3 mapped = vec3(1.0) - exp(-hdrColor * u_exposure);

        float oldLum = Luminance(hdrColor);
        float num = oldLum * (1.0 + oldLum / (u_exposure*u_exposure));
        float newLum = num / (1.0 + oldLum);
        vec3 mapped = hdrColor * (newLum / oldLum);
    
        return vec4(mapped, 1.0);
    }
]]


--- @class HDR: BasePostProcessingEffect
---
--- @field private hdrCanvas love.Canvas
--- @field private shader love.Shader
--- @field public exposure number
---
--- @overload fun(screenSize: Vector2, exposure: number): HDR
local HDR = BaseEffect:extend("HDR")


function HDR:new(screenSize, exposure)
    self.hdrCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height)
    self.exposure = exposure
end


function HDR:onPostRender(renderer, canvas)
    hdrShader:use()
    hdrShader:sendUniform("u_exposure", self.exposure)

    love.graphics.setCanvas(self.hdrCanvas)
    love.graphics.draw(canvas)

    return self.hdrCanvas
end


return HDR