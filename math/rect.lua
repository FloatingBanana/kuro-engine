local Inter2d = require "engine.math.intersection2d"
local CStruct = require "engine.misc.cstruct"


--- @class Rect : CStruct
---
--- @field public position Vector2
--- @field public size Vector2
---
--- @field public center Vector2
--- @field public topLeft Vector2
--- @field public bottomRight Vector2
---
--- @overload fun(pos: Vector2, size: Vector2): Rect
local Rect = CStruct("Rect", [[
    Vector2 position;
    Vector2 size;
]])

function Rect:new(pos, size)
    self.position = pos
    self.size = size
end


---@param pos Vector2
---@return boolean
function Rect:isPointInside(pos)
    return Inter2d.point_AABB(pos, self.topLeft, self.bottomRight)
end


---@param rect Rect
---@return boolean
function Rect:testCollision(rect)
    return Inter2d.AABB_AABB(self.topLeft, self.bottomRight, rect.topLeft, rect.bottomRight)
end


---@return Rect
function Rect:clone()
    return Rect(self.position:clone(), self.size:clone())
end


---@return number, number, number, number
function Rect:split()
    return self.position.x, self.position.y, self.size.width, self.size.height
end


---@private
function Rect:__index(key)
    if key == "topLeft" or key == "pos" then
        return self.position
    end

    if key == "center" then
        return self.position + (self.size / 2)
    end

    if key == "bottomRight" then
        return self.position + self.size
    end

    return Rect[key]
end


---@private
function Rect:__newindex(key, value)
    if key == "topLeft" or key == "pos" then
        self.position = value
        return
    end

    if key == "center" then
        self.position = value - (self.size / 2)
        return
    end

    if key == "bottomRight" then
        self.position = value - self.size
        return
    end

    rawset(self, key, value)
end


---@private
function Rect:__tostring()
    return ("Rect(x: %d, y: %d, w: %d, h: %d)"):format(self.position.x, self.position.y, self.size.width, self.size.height)
end


return Rect