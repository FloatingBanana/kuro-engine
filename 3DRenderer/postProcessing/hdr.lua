local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

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
---
--- @overload fun(screenSize: Vector2, exposure: number): HDR
local HDR = BaseEffect:extend()


function HDR:new(screenSize, exposure)
    self.hdrCanvas = lg.newCanvas(screenSize.width, screenSize.height)
    self.shader = lg.newShader(hdrShader)

    self:setExposure(exposure)
end


function HDR:applyPostRender(device, canvas, view, projection)
    lg.setCanvas(self.hdrCanvas)
    lg.setShader(self.shader)

    lg.draw(canvas)

    lg.setCanvas()
    lg.setShader()

    return self.hdrCanvas
end


--- @param exposure number
function HDR:setExposure(exposure)
    self.shader:send("u_exposure", exposure)
end


return HDR