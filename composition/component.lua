local Object = require "engine.3rdparty.classic.classic"

---@class Component: Object
---
---@field public enabled boolean
---@field public entity Entity
local Component = Object:extend("Component")

function Component:new()
end

function Component:onAttach(entity)end
function Component:onDetach(entity)end

function Component:onEntityAdded(entity)end
function Component:onEntityRemoved(entity)end

function Component:update(dt)end
function Component:draw()end
function Component:keypressed(k)end
function Component:keyreleased(k)end
function Component:textinput(t)end
function Component:mousepressed(button, isTouch)end
function Component:mousereleased(button, isTouch)end
function Component:mousemoved(dx, dy)end
function Component:wheelmoved(x, y)end

return Component