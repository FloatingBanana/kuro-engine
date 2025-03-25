local Object = require "engine.3rdparty.classic.classic"

--- @class BasePostProcessingEffect: Object
---
--- @operator call: BasePostProcessingEffect
local baseEffect = Object:extend("BasePostProcessingEffect")


--- @param renderer BaseRenderer
--- @param camera Camera3D
function baseEffect:onPreRender(renderer, camera)

end


--- @param renderer BaseRenderer
--- @param camera Camera3D
--- @param canvas love.Canvas
--- @return love.Canvas
--- @nodiscard
function baseEffect:onPostRender(renderer, camera, canvas)
    return canvas
end


return baseEffect