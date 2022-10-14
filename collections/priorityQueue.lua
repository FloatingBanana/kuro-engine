-- Priority queue using binary heap: https://www.geeksforgeeks.org/priority-queue-using-binary-heap/
local PriorityQueue = Object:extend()

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

function PriorityQueue:peek()
    assert(self.pointer > -1, "Queue is empty")
    return self.priorities[0], self.items[0]
end

function PriorityQueue:push(priotity, item)
    self.pointer = self.pointer + 1

    self.priorities[self.pointer] = priotity
    self.items[self.pointer] = item

    self:__shiftUp(self.pointer)
end

function PriorityQueue:pop()
    local priority, item = self:peek()
    self:__swap(0, self.pointer)

    self.priorities[self.pointer] = nil -- Free item in case it's a reference type
    self.pointer = self.pointer - 1

    self:__shiftDown(0)
    return priority, item
end

function PriorityQueue:changePriority(index, priority)
    local oldPriority = self.priorities[index]
    self.priorities[index] = priority

    if (priority > oldPriority) then
        self:__shiftUp(index)
    else
        self:__shiftDown(index)
    end
end

function PriorityQueue:remove(index)
    self:changePriority(index, self.priorities[0] + 1)
    return self:pop()
end

function PriorityQueue:clear()
    self.items = {}
    self.priorities = {}
    self.pointer = -1
end

function PriorityQueue:getLength()
    return self.pointer + 2
end

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

function PriorityQueue:iterate()
    return iter, self, -1
end

return PriorityQueue