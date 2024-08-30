local Object = require "engine.3rdparty.classic.classic"
local Matrix = require "engine.math.matrix"


---@class BoundingBox: Object
---
---@field public min Vector3
---@field public max Vector3
---@field public size Vector3
---@field public center Vector3
---
---@overload fun(min: Vector3, max: Vector3): BoundingBox
local BoundingBox = Object:extend("BoundingBox")

function BoundingBox:new(min, max)
    self.min = min
    self.max = max
end

---@private
function BoundingBox:__index(key)
    if key == "center" then
        return (self.max + self.min):multiply(0.5)
    end
    if key == "size" then
        return (self.max - self.min):abs()
    end

    return BoundingBox[key]
end

---@private
function BoundingBox:__newindex(key, value)
    if key == "center" then
        local halfSize = self.size * 0.5
        self.min = value - halfSize
        self.max = value + halfSize
        return
    end

    if key == "size" then
        local center = self.center
        local halfSize = value * 0.5
        self.min = center - halfSize
        self.max = center + halfSize
        return
    end

    rawset(self, key, value)
end


---@param mat Matrix
---@return self
function BoundingBox:transform(mat)
    self.min, self.max = self:getMinMaxTransformed(mat)
    return self
end


---@param point Vector3
---@return Vector3
function BoundingBox:getNearestPoint(point)
    return point:clone():clamp(self.min, self.max)
end


---@param box BoundingBox
---@return boolean
function BoundingBox:testIntersection(box)
    return self.min < box.max and box.min < self.max
end


---@param mat Matrix
---@return Vector3, Vector3
function BoundingBox:getMinMaxTransformed(mat)
    local trCenter = self.center:transform(mat)

    local abs = math.abs
    local absMat = Matrix(
        abs(mat.m11), abs(mat.m12), abs(mat.m13), 0,
        abs(mat.m21), abs(mat.m22), abs(mat.m23), 0,
        abs(mat.m31), abs(mat.m32), abs(mat.m33), 0,
        0,            0,            0,            1
    )

    local trSize = self.size:transform(absMat):multiply(0.5)

    return trCenter - trSize, trCenter + trSize
end


---@return BoundingBox
function BoundingBox:clone()
    return BoundingBox(self.min, self.max)
end


return BoundingBox