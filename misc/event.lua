local Object = require "engine.3rdparty.classic.classic"
local Lume = require "engine.3rdparty.lume"

--- @alias EventCallback fun(event: Event, ...)


--- @class Event: Object
--- 
--- @field private callbacks table<function, EventCallback>
--- @overload fun(): Event
local Event = Object:extend("Event")


function Event:new()
    self.callbacks = {}
end


---@param fn EventCallback
---@param once boolean?
---@return Event
function Event:addCallback(fn, once)
    local callback = fn

    if once then
        callback = function(...)
            fn(...)
            self:removeCallback(fn)
        end
    end

    self.callbacks[fn] = callback
    return self
end


---@param fn EventCallback
---@return Event
function Event:removeCallback(fn)
    self.callbacks[fn] = nil
    return self
end


---@param ... unknown
---@return Event
function Event:trigger(...)
    for _, callback in pairs(self.callbacks) do
        callback(self, ...)
    end
    return self
end


---@return Event
function Event:clear()
    self.callbacks = {}
    return self
end


return Event