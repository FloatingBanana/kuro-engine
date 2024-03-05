local Object = require "engine.3rdparty.classic.classic"
local Event = require "engine.misc.event"

--- @class Timer: Object
---
--- @field public time number
--- @field public duration number
--- @field public progress number
--- @field public isLoop boolean
--- @field public running boolean
--- @field public justEnded boolean
--- @field public onEndedEvent Event
---
--- @overload fun(initialTime: number, duration: number, isLoop: boolean): Timer
local Timer = Object:extend("Timer")


function Timer:new(initialTime, duration, isLoop)
    self.time = initialTime
    self.duration = duration
    self.isLoop = isLoop

    self.running = false
    self.justEnded = false
    self.autoRestart = true

    self.onEndedEvent = Event()
end

---@private
function Timer:__index(k)
    if k == "progress" then
        return self.time / self.duration
    end

    return Timer[k]
end

---@private
function Timer:__newindex(k, v)
    if k == "progress" then
        self.time = self.duration * v
    end
end


function Timer:update(dt)
    self.justEnded = false

    if self.running then
        self.time = self.time + dt

        if self.time >= self.duration then
            if self.isLoop then
                self.time = self.time - self.duration
            else
                self.running = false
                self.time = self.autoRestart and 0 or self.time
            end
            self.justEnded = true
            self.onEndedEvent:trigger(self)
        end
    end

    return self
end


---@returned Timer
function Timer:play()
    self.running = true
    return self
end


---@returned Timer
function Timer:stop()
    if self.running then
        self.onEndedEvent:trigger(self)
    end

    self.running = false
    return self
end


---@returned Timer
function Timer:restart()
    self.running = false
    self.justEnded = false
    self.time = 0

    return self
end

return Timer