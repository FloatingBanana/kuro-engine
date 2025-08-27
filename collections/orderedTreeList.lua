local Object = require "engine.3rdparty.classic.classic"
local cleartable = require "table.clear"

local tempList = setmetatable({}, {__mode = 'v'})


---@class OrderedTreeList: {[integer]: any}
---
---@field private nodes integer[]
---
---@overload fun(): OrderedTreeList
local OrderedTreeList = Object:extend("OrderedTreeList")

function OrderedTreeList:new()
    self._nodes = {
        [0] = 0 -- Root node
    }
end


---@param item any
---@param parent integer?
---@param position integer?
---@return integer
function OrderedTreeList:add(item, parent, position)
    parent = parent or 0
    self._nodes[parent] = self:getChildCount(parent) + 1

    local index = self:getChildIndexAt(parent, position or -1)
    table.insert(self._nodes, index, 0)
    table.insert(self, index, item)

    return index
end


---@param index integer
---@param moveChildrenToParent boolean
---@return ...
function OrderedTreeList:remove(index, moveChildrenToParent)
    local parent = self:getParentIndex(index)
    local range = 1

    if not moveChildrenToParent then
        range = self:getChildCount(index, true) + 1
    end

    self._nodes[parent] = self._nodes[parent] + self:getChildCount(index, false) - 1

    local iStart = index + range
    local iEnd   = #self + range

    table.move(self, index, iStart - 1, 1, tempList)
    table.move(self._nodes, iStart, iEnd, index)
    table.move(self, iStart, iEnd, index)

    return table.unpack(tempList, 1, range)
end


---@param index integer
---@param newParentIndex integer
---@param childPosition integer?
function OrderedTreeList:setParent(index, newParentIndex, childPosition)
    local oldParentIndex = self:getParentIndex(index)
    self._nodes[oldParentIndex] = self._nodes[oldParentIndex] - 1
    self._nodes[newParentIndex] = self._nodes[newParentIndex] + 1

    assert(self._nodes[index], "Index out of bounds")
    assert(self._nodes[newParentIndex], "Parent index out of bounds")

    local rangeIndex = index + self:getChildCount(index, true)
    local newIndex = self:getChildIndexAt(newParentIndex, childPosition or -1)

    assert(newParentIndex < index or newParentIndex > rangeIndex, "Cannot move item to its own subtree")

    local offset     = (newIndex > index) and -1 or 0
    local startIndex = (newIndex > index) and index or rangeIndex
    local dir        = (newIndex > index) and 1 or -1

    for i=index, rangeIndex do
        for j=startIndex, newIndex + offset - dir, dir do
            self[j], self[j+dir] = self[j+dir], self[j]
            self._nodes[j], self._nodes[j+dir] = self._nodes[j+dir], self._nodes[j]
        end
    end
end


---@param index integer
---@return integer?
function OrderedTreeList:getParentIndex(index)
    assert(self._nodes[index], "Index out of bounds")

    if index == 0 then
        return nil
    end

    local parent = index
    local childCount = 0

    repeat
        parent = parent - 1
        childCount = childCount + self:getChildCount(parent)
    until parent + childCount >= index

    return parent
end


---@param item any
---@param parentIndex integer?
---@param includeSubchildren boolean?
---@return any
function OrderedTreeList:find(item, parentIndex, includeSubchildren)
    assert(self._nodes[parentIndex or 0], "Parent index out of bounds")

    local index = parentIndex or 0
    local finalIndex = index + self:getChildCount(index)
    local remainingSubchildren = 0

    while index < finalIndex do
        index = index + 1

        if (includeSubchildren or remainingSubchildren == 0) and self[index] == item then
            return index
        end

        finalIndex = finalIndex + self:getChildCount(index)
        remainingSubchildren = math.max(0, remainingSubchildren - 1) + self:getChildCount(index)
    end

    return nil
end


---@param index integer
---@param includeSubchildren boolean?
---@return integer
function OrderedTreeList:getChildCount(index, includeSubchildren)
    assert(self._nodes[index], "Index out of bounds")

    if includeSubchildren then
        local childCount = self._nodes[index]
        local finalIndex = index

        while finalIndex < index + childCount do
            finalIndex = finalIndex + 1
            childCount = childCount + self._nodes[finalIndex]
        end

        return childCount
    end

    return self._nodes[index]
end


---@param index integer
---@param includeSubchildren boolean?
---@return ...
function OrderedTreeList:getChildrenIndices(index, includeSubchildren)
    assert(self._nodes[index], "Index out of bounds")
    cleartable(tempList)

    local remainingSubchildren = 0
    local finalIndex = index + self:getChildCount(index)

    while index < finalIndex do
        index = index + 1

        if includeSubchildren or remainingSubchildren == 0 then
            table.insert(tempList, index)
        end

        finalIndex = finalIndex + self:getChildCount(index)
        remainingSubchildren = math.max(0, remainingSubchildren - 1) + self:getChildCount(index)
    end

    return unpack(tempList)
end


---@param parentIndex integer
---@param position integer
---@return integer
function OrderedTreeList:getChildIndexAt(parentIndex, position)
    local childCount = self:getChildCount(parentIndex, false)

    if position < 0 then
        position = childCount + position + 1
    end

    assert(position > 0 and position <= childCount, "Position out of bounds")

    local index = parentIndex + 1
    for i=2, position do
        index = index + self:getChildCount(index, true) + 1
    end

    return index
end


---@private
---@return string
function OrderedTreeList:__tostring()
    local str = require("string.buffer").new()

    local treeLevels = {self:getChildCount(0)}
    for i, item in ipairs(self) do
        treeLevels[#treeLevels] = treeLevels[#treeLevels] - 1

        str:put(string.rep("  ", #treeLevels - 1))
        str:put(item)
        str:put("\n")

        if self:getChildCount(i) > 0 then
            table.insert(treeLevels, self:getChildCount(i))
        end

        while treeLevels[#treeLevels] == 0 do
            table.remove(treeLevels)
        end
    end

    return str:tostring()
end


return OrderedTreeList