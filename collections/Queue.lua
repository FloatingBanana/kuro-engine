local Deque = require "engine.collections.deque"
local Queue = Object:extend()

function Queue:new(...)
    self.first = 0
    self.last = -1

    for i=1, select("#", ...)do
        self:push(select(i, ...))
    end
end

function Queue:push(item)
    self.last = self.last + 1
    self[self.last] = item
end

function Queue:pop()
    assert(self:getLength() > 0, "Queue is empty")

    local item = self:peek()
    self[self.first] = nil
    self.first = self.first + 1

    return item
end

function Queue:peek()
    return self[self.first]
end

-- Reusing some functions from Deque since they would have the same logic
Queue.getLength = Deque.getLength
Queue.getItem = Deque.getItem
Queue.iterate = Deque.iterate

return Queue