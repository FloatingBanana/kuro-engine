local Object = require "engine.3rdparty.classic.classic"

---
--- A double queue that can be pushed/popped from both sides.
---
--- @class Deque
---
--- @operator call: Deque
local Deque = Object:extend()

function Deque:new(...)
    self.first = 0
    self.last = -1

    for i=1, select("#", ...)do
        self:pushRight(select(i, ...))
    end
end


--- Pushes an item to the left side of the deque
--- @param item any: Item to be pushed
function Deque:pushLeft(item)
    self.first = self.first - 1
    self[self.first] = item
end


--- Pushes an item to the right side of the deque
--- @param item any: Item to be pushed
function Deque:pushRight(item)
    self.last = self.last + 1
    self[self.last] = item
end


--- Removes the leftmost item and returns it
--- @return any: The popped item
function Deque:popLeft()
    assert(self:getLength() > 0, "Deque is empty")

    local item = self:peekLeft()
    self[self.first] = nil
    self.first = self.first + 1

    return item
end


--- Removes the rightmost item and returns it
--- @return any: The popped item
function Deque:popRight()
    assert(self:getLength() > 0, "Deque is empty")

    local item = self:peekRight()
    self[self.last] = nil
    self.last = self.last - 1

    return item
end


--- Returns the leftmost item without removing it
--- @return any: The leftmost item
function Deque:peekLeft()
    return self[self.first]
end


--- Returns the rightmost item without removing it
--- @return any: The rightmost item
function Deque:peekRight()
    return self[self.last]
end


--- Get the number of items in this deque
--- @return number: The number of items
function Deque:getLength()
    return math.abs(self.last - self.first + 1)
end


--- Gets item at the specified index
--- @param index number: Index of item
--- @return any: The item at the specified index
function Deque:getItem(index)
    return self[self.first + (index - 1)]
end


local function iter(this, i)
    i = i+1
    local item = this:getItem(i)

    if item then
        return item, i
    end
end


--- Loops through all items in this deque. Use this instead of `ipairs`
--- @return function: Iterator
--- @return Deque: This deque
--- @return number: First index
function Deque:iterate()
    return iter, self, 0
end

return Deque