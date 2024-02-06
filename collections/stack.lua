local Object = require "engine.3rdparty.classic.classic"

---
--- A list of data that follows the "Last In, First Out" (LIFO) principle.
---
--- @class Stack: {[integer]: any}
---
--- @operator call: Stack
local Stack = Object:extend("Stack")

function Stack:new(...)
    for i=1, select("#", ...)do
        self:push(select(i, ...))
    end
end


--- Pushes an item to the top of the stack
--- @param item any: Item to be pushed
function Stack:push(item)
    table.insert(self, item)
end


--- Removes the topmost item and returns it
--- @return any: The popped item
function Stack:pop()
    return table.remove(self)
end


--- Returns the topmost item without removing it
--- @return any: The topmost item
function Stack:peek()
    return self[#self]
end

return Stack