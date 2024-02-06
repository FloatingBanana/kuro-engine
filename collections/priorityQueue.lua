local Object = require "engine.3rdparty.classic.classic"
-- Priority queue using binary heap: https://www.geeksforgeeks.org/priority-queue-using-binary-heap/

local floor = math.floor
local function parent(index)
    return floor((index - 1) / 2)
end

local function leftChild(index)
    return (2 * index) + 1
end

local function rightChild(index)
    return (2 * index) + 2
end


---
--- A queue that's sorted based on the specified priority of each element. Based on binary heap algorithm.
---
--- @class PriorityQueue
---
--- @operator call: PriorityQueue
local PriorityQueue = Object:extend("PriorityQueue")

function PriorityQueue:new()
    self.items = {}
    self.priorities = {}

    self.pointer = -1
end

function PriorityQueue:__swap(index1, index2)
    local priorities = self.priorities
    local items = self.items

    local tempPriority, tempItem = priorities[index1], items[index1]
    priorities[index1], items[index1] = priorities[index2], items[index2]
    priorities[index2], items[index2] = tempPriority, tempItem
end

function PriorityQueue:__shiftUp(index)
    local priorities = self.priorities

    while (index > 0 and priorities[parent(index)] < priorities[index]) do
        self:__swap(parent(index), index)

        index = parent(index)
    end
end

function PriorityQueue:__shiftDown(index)
    local priorities = self.priorities
    local max = index

    local left = leftChild(index)
    if left <= self.pointer and priorities[left] > priorities[max] then
        max = left
    end

    local right = rightChild(index)
    if right <= self.pointer and priorities[right] > priorities[max] then
        max = right
    end

    if index ~= max then
        self:__swap(max, index)
        self:__shiftDown(max)
    end
end


--- Returns the item with highest priority without removing it
--- @return number: Item priority
--- @return any: The highest priotity item
function PriorityQueue:peek()
    assert(self.pointer > -1, "Queue is empty")
    return self.priorities[0], self.items[0]
end



--- Pushes an item to the queue
--- @param priority integer: Item priority
--- @param item any: Item to be pushed
function PriorityQueue:push(priority, item)
    self.pointer = self.pointer + 1

    self.priorities[self.pointer] = priority
    self.items[self.pointer] = item

    self:__shiftUp(self.pointer)
end


--- Removes the item with highest priority and returns it
--- @return number: Item priority
--- @return any: The popped item
function PriorityQueue:pop()
    local priority, item = self:peek()
    self:__swap(0, self.pointer)

    self.priorities[self.pointer] = nil -- Free item in case it's a reference type
    self.pointer = self.pointer - 1

    self:__shiftDown(0)
    return priority, item
end


--- Changes priority of the specified item
--- @param index number: Index of item
--- @param priority number: Priority to be set
function PriorityQueue:changePriority(index, priority)
    local oldPriority = self.priorities[index]
    self.priorities[index] = priority

    if (priority > oldPriority) then
        self:__shiftUp(index)
    else
        self:__shiftDown(index)
    end
end


--- Removes the specified item and returns it
--- @param index number: Index of item
--- @return number: Item priority
--- @return any: The removed item
function PriorityQueue:remove(index)
    self:changePriority(index, self.priorities[0] + 1)
    return self:pop()
end


--- Remove all items from the queue
function PriorityQueue:clear()
    self.items = {}
    self.priorities = {}
    self.pointer = -1
end


--- Get the number of items in this queue
--- @return number: The number of items
function PriorityQueue:getLength()
    return self.pointer + 1
end


--- Gets item at the specified index
--- @param index number: Index of item
--- @return number: Item priority
--- @return any: The item at the specified index
function PriorityQueue:getItem(index)
    return self.priorities[index], self.items[index]
end



local function iter(this, i)
    i = i+1
    local priority, item = this:getItem(i)

    if item then
        return i, priority, item
    end
end

--- Loops through all items in this queue. Use this instead of `ipairs`
---
--- The loop signature should be:
--- ```lua
--- for index, priority, item in this:iterate() do end
--- ```
--- @return function: Iterator
--- @return PriorityQueue: This queue
--- @return number: First index
function PriorityQueue:iterate()
    return iter, self, -1
end

return PriorityQueue