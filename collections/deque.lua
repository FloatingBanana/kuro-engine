local Object = require "engine.3rdparty.classic.classic"

---
--- A double queue that can be pushed/popped from both sides.
---
--- @class Deque
---
--- @operator call: Deque
local Deque = Object:extend("Deque")

function Deque:new(...)
    for i=1, select("#", ...)do
        self:pushRight(select(i, ...))
    end
end


--- Pushes an item to the left side of the deque
--- @param item any: Item to be pushed
function Deque:pushLeft(item)
    table.insert(self, 1, item)
end


--- Pushes an item to the right side of the deque
--- @param item any: Item to be pushed
function Deque:pushRight(item)
    table.insert(self, item)
end


--- Removes the leftmost item and returns it
--- @return any: The popped item
function Deque:popLeft()
    assert(self[1], "Deque is empty")
    return table.remove(self, 1)
end


--- Removes the rightmost item and returns it
--- @return any: The popped item
function Deque:popRight()
    assert(self[1], "Deque is empty")
    return table.remove(self)
end


--- Returns the leftmost item without removing it
--- @return any: The leftmost item
function Deque:peekLeft()
    return self[1]
end


--- Returns the rightmost item without removing it
--- @return any: The rightmost item
function Deque:peekRight()
    return self[#self]
end


return Deque