local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"

local hdrShader = [[
    uniform float u_exposure;
    
    vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
        vec3 hdrColor = Texel(texture, texcoords).rgb;
        vec3 mapped = vec3(1.0) - exp(-hdrColor * u_exposure);
    
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
    self.shader = love.graphics.newShader(hdrShader)
    self.exposure = exposure

    self:setExposure(exposure)
end


function HDR:onPostRender(renderer, canvas, camera)
    love.graphics.setCanvas(self.hdrCanvas)
    love.graphics.setShader(self.shader)

    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return self.hdrCanvas
end


--- @param exposure number
function HDR:setExposure(exposure)
    self.shader:send("u_exposure", exposure)
    self.exposure = exposure
end


return HDR