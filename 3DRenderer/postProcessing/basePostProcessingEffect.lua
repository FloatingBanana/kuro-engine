--- @class BasePostProcessingEffect: Object
---
--- @operator call: BasePostProcessingEffect
local baseEffect = Object:extend()


--- @param renderer BaseRenderer
--- @param gbuffer GBuffer
--- @param view Matrix
--- @param projection Matrix
function baseEffect:deferredPreRender(renderer, gbuffer, view, projection)

end


--- @param light BaseLight
--- @param shader love.Shader
function baseEffect:onLightRender(light, shader)
    
end


--- @param renderer BaseRenderer
--- @param canvas love.Canvas
--- @param view Matrix
--- @param projection Matrix
--- @return love.Canvas
--- @nodiscard
function baseEffect:applyPostRender(renderer, canvas, view, projection)
    return canvas
end


return baseEffect