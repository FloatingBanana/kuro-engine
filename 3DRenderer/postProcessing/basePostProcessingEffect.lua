--- @class BasePostProcessingEffect: Object
---
--- @operator call: BasePostProcessingEffect
local baseEffect = Object:extend()


--- @param renderer BaseRenderer
--- @param view Matrix
--- @param projection Matrix
function baseEffect:onPreRender(renderer, view, projection)

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
function baseEffect:onPostRender(renderer, canvas, view, projection)
    return canvas
end


return baseEffect