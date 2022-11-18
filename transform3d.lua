local Matrix = require "engine.math.matrix"
local Transform = Object:extend()

local function rebuildMatrix(matrix, rotation, scale)
    assert(matrix:canDecompose(), "Can't decompose matrix")

    local matPosition, matScale, matRotation = matrix:decompose()
    return Matrix.createTransformationMatrix(rotation or matRotation, scale or matScale, matPosition)
end


function Transform:new(matrix, parent)
    self.localMatrix = matrix

    self.parent = parent
    self.children = {}
end

function Transform:__index(key)
    if key == "localPosition" then
        return self.localMatrix.translation
    end

    if key == "localScale" then
        return self.localMatrix.scale
    end

    if key == "localRotation" then
        return self.localMatrix.rotation
    end

    if key == "globalPosition" then
        return self.globalMatrix.translation
    end

    if key == "globalScale" then
        return self.globalMatrix.scale
    end

    if key == "globalRotation" then
        return self.globalMatrix.rotation
    end

    if key == "parentGlobalMatrix" then
        return self.parent.globalMatrix or Matrix.identity()
    end

    if key == "globalMatrix" then
        return self.localMatrix * self.parentGlobalMatrix
    end

    return Object[key]
end

function Transform:__newindex(key, value)
    if key == "localPosition" then
        self.localMatrix.translation = value
        return
    end

    if key == "localScale" then
        self.localMatrix = rebuildMatrix(self.localMatrix, nil, value)
        return
    end

    if key == "localRotation" then
        self.localMatrix = rebuildMatrix(self.localMatrix, value, nil)
        return
    end

    if key == "globalPosition" then
        self.localMatrix.translation = value:transform(self.parentGlobalMatrix.inverse)
        return
    end

    if key == "globalScale" then
        self.globalMatrix = rebuildMatrix(self.globalMatrix, nil, value)
        return
    end

    if key == "globalRotation" then
        self.globalMatrix = rebuildMatrix(self.globalMatrix, value, nil)
        return
    end

    if key == "globalMatrix" then
        self.localMatrix = value * self.parentGlobalMatrix.inverse
    end

    rawset(self, key, value)
end

function Transform:addChild(child)
    self.children[child] = true
    child.parent = self
end

function Transform:removeChild(child)
    self.children[child] = nil
    child.parent = nil
end

return Transform