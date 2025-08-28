local Object = require "engine.3rdparty.classic.classic"


---
--- A list of data that follows the "First In, First Out" (FIFO) principle.
---
--- @class Queue
---
--- @operator call: Queue
local Queue = Object:extend("Queue")

function Queue:new(...)
    for i=1, select("#", ...)do
        self:push(select(i, ...))
    end
end


--- Pushes an item to the top of the queue
--- @param item any: Item to be pushed
function Queue:push(item)
    table.insert(self, item)
end


--- Removes the bottommost item and returns it
--- @return any: The popped item
function Queue:pop()
    assert(self[1], "Queue is empty")
    return table.remove(self, 1)
end


--- Returns the bottommost item without removing it
--- @return any: The bottommost item
function Queue:peek()
    return self[1]
end


return Queue