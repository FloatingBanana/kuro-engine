local Object = require "engine.3rdparty.classic.classic"
local Lume = require "engine.3rdparty.lume"

--- @alias EventCallback fun(event: Event, ...)


--- @class Event: Object
--- 
--- @field private callbacks EventCallback[]
local Event = Object:extend()


function Event:new()
    self.callbacks = {}
end


---@param fn EventCallback
---@return Event
function Event:addCallback(fn)
    table.insert(self.callbacks, fn)
    return self
end


---@param fn EventCallback
---@return Event
function Event:removeCallback(fn)
    table.remove(self.callbacks, Lume.find(self.callbacks, fn))
    return self
end


---@param ... unknown
---@return Event
function Event:trigger(...)
    for i, fn in Lume.ripairs(self.callbacks) do
        fn(self, ...)
    end
    return self
end


---@return Event
function Event:clear()
    self.callbacks = {}
    return self
end


return Event