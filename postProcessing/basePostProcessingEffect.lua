local Object = require "engine.3rdparty.classic.classic"

--- @class BasePostProcessingEffect: Object
---
--- @operator call: BasePostProcessingEffect
local baseEffect = Object:extend("BasePostProcessingEffect")


--- @param renderer BaseRenderer
function baseEffect:onPreRender(renderer)

end


--- @param renderer BaseRenderer
--- @param canvas love.Canvas
--- @return love.Canvas
--- @nodiscard
function baseEffect:onPostRender(renderer, canvas)
    return canvas
end


return baseEffect