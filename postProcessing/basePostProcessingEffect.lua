local Object = require "engine.3rdparty.classic.classic"

--- @class BasePostProcessingEffect: Object
---
--- @operator call: BasePostProcessingEffect
local baseEffect = Object:extend()


--- @param renderer BaseRenderer
--- @param camera Camera
function baseEffect:onPreRender(renderer, camera)

end


--- @param light BaseLight
--- @param shader love.Shader
function baseEffect:onLightRender(light, shader)
    
end


--- @param renderer BaseRenderer
--- @param canvas love.Canvas
--- @param camera Camera
--- @return love.Canvas
--- @nodiscard
function baseEffect:onPostRender(renderer, canvas, camera)
    return canvas
end


return baseEffect