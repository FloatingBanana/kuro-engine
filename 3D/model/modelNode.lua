local Lume   = require "engine.3rdparty.lume"
local Object = require "engine.3rdparty.classic.classic"

--- @class ModelNode: Object
---
--- @field model Model
--- @field name string
--- @field localMatrix Matrix
--- @field parent ModelNode?
--- @field children ModelNode[]
---
---@overload fun(model: Model, name: string, localMatrix: Matrix): ModelNode
local Node = Object:extend("ModelNode")

function Node:new(model, name, localMatrix)
    self.model = model
    self.name = name
    self.localMatrix = localMatrix
    self.parent = nil
    self.children = {}
end


--- @param topmostNode ModelNode|string|nil
--- @return Matrix
function Node:getGlobalMatrix(topmostNode)
    local top = topmostNode
    local globalMatrix = self.localMatrix:clone()

    if type(topmostNode) == "string" then
        top = self.model.nodes[topmostNode]
    end

    local currParent = self.parent
    while currParent and currParent ~= top do
        globalMatrix:multiply(currParent.localMatrix)
        currParent = currParent.parent
    end

    return globalMatrix
end


--- @param child ModelNode
function Node:addChild(child)
    assert(not child.parent, "Child already has a parent")

    table.insert(self.children, child)
    child.parent = self
end


--- @param child ModelNode
function Node:removeChild(child)
    local index = Lume.find(self.children, child)

    assert(index, "Node is not in the children list")
    table.remove(self.children, index)
end


return Node