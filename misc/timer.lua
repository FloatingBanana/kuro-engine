--- @class Timer: Object
---
--- @field public time number
--- @field public duration number
--- @field public isLoop boolean
--- @field public running boolean
--- @field public justEnded boolean
---
--- @overload fun(initialTime: number, duration: number, isLoop: boolean): Timer
local Timer = Object:extend()


function Timer:new(initialTime, duration, isLoop)
    self.time = initialTime
    self.duration = duration
    self.isLoop = isLoop

    self.running = false
    self.justEnded = false
end


function Timer:update(dt)
    self.justEnded = false

    if self.running then
        self.time = self.time + dt

        if self.time >= self.duration then
            if self.isLoop then
                self.time = self.time - self.duration
            end
            self.justEnded = true
            self.running = false
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