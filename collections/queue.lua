local Deque = require "engine.collections.deque"


---
--- A list of data that follows the "First In, First Out" (FIFO) principle.
---
--- @class Queue
---
--- @operator call: Queue
local Queue = Object:extend()

function Queue:new(...)
    self.first = 0
    self.last = -1

    for i=1, select("#", ...)do
        self:push(select(i, ...))
    end
end


--- Pushes an item to the top of the queue
--- @param item any: Item to be pushed
function Queue:push(item)
    self.last = self.last + 1
    self[self.last] = item
end


--- Removes the bottommost item and returns it
--- @return any: The popped item
function Queue:pop()
    assert(self:getLength() > 0, "Queue is empty")

    local item = self:peek()
    self[self.first] = nil
    self.first = self.first + 1

    return item
end


--- Returns the bottommost item without removing it
--- @return any: The bottommost item
function Queue:peek()
    return self[self.first]
end

-- Reusing some functions from Deque since they would have the same logic

--- Get the number of items in this queue
--- @return number: The number of items
function Queue:getLength()
    return math.abs(self.last - self.first + 1)
end

--- Gets item at the specified index
--- @param index number: Index of item
--- @return any: The item at the specified index
function Queue:getItem(index)
    return self[self.first + (index - 1)]
end


--- Loops through all items in this Queue. Use this instead of `ipairs`
--- @return function: Iterator
--- @return Queue: This queue
--- @return number: First index
function Queue:iterate()
    return Deque.iterate(self) --- @diagnostic disable-line
end


return Queue