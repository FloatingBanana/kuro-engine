local Object = require "engine.3rdparty.classic.classic"

---@class Component: Object
---
---@field public enabled boolean
local Component = Object:extend("Component")

function Component:new()
end

function Component:onAttach(entity)end
function Component:onDetach(entity)end

function Component:onEntityAdded(entity)end
function Component:onEntityRemoved(entity)end

function Component:update(entity, dt)end
function Component:draw(entity)end
function Component:keypressed(entity, k)end
function Component:keyreleased(entity, k)end
function Component:textinput(entity, t)end
function Component:mousepressed(entity, button, isTouch)end
function Component:mousereleased(entity, button, isTouch)end
function Component:mousemoved(entity, dx, dy)end
function Component:wheelmoved(entity, x, y)end

return Component