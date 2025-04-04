local CStruct = require "engine.misc.cstruct"
local Matrix3 = require "engine.math.matrix3"
local Vector3 = require "engine.math.vector3"


---@class BoundingBox: CStruct
---
---@field public min Vector3
---@field public max Vector3
---@field public size Vector3
---@field public center Vector3
---
---@overload fun(min: Vector3, max: Vector3): BoundingBox
local BoundingBox = CStruct("BoundingBox", [[
    Vector3 min, max;
]])

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


---@param mat Matrix4
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


---@param mat Matrix4
---@return Vector3, Vector3
function BoundingBox:getMinMaxTransformed(mat)
    local trCenter = self.center:transform(mat)

    local abs = math.abs
    local absMat = Matrix3(
        abs(mat.m11), abs(mat.m12), abs(mat.m13),
        abs(mat.m21), abs(mat.m22), abs(mat.m23),
        abs(mat.m31), abs(mat.m32), abs(mat.m33)
    )

    local trSize = self.size:transform(absMat):multiply(0.5)

    return trCenter - trSize, trCenter + trSize
end


---@return BoundingBox
function BoundingBox:clone()
    return BoundingBox(self.min, self.max)
end


---@return Vector3, Vector3
function BoundingBox:split()
    return self.min, self.max
end



function BoundingBox.CreateFromCenterSize(center, size)
    local halfSize = size / 2
    return BoundingBox(center - halfSize, center + halfSize)
end


function BoundingBox.CreateFromPoints(...)
    local min = Vector3(math.huge)
    local max = Vector3(-math.huge)

    for i=1, select("#", ...) do
        local point = select(i, ...)

        min.x = math.min(min.x, point.x)
        min.y = math.min(min.y, point.y)
        min.z = math.min(min.z, point.z)

        max.x = math.min(max.x, point.x)
        max.y = math.min(max.y, point.y)
        max.z = math.min(max.z, point.z)
    end

    return BoundingBox(min, max)
end


return BoundingBox