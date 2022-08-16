local Inter2d = require "engine.intersection2d"
local CStruct = require "engine.cstruct"
local Rect = CStruct("Rect", [[
    brinevector position;
    brinevector size;
]])

function Rect:new(pos, size)
    self.position = pos
    self.size = size
end

function Rect:isPointInside(pos)
    return Inter2d.point_AABB(pos, self.topLeft, self.bottomRight)
end

function Rect:testCollision(rect)
    return Inter2d.AABB_AABB(self.topLeft, self.bottomRight, rect.topLeft, rect.bottomRight)
end

function Rect:clone()
    return Rect(self.position:clone(), self.size:clone())
end

function Rect:split()
    return self.position.x, self.position.y, self.size.width, self.size.height
end

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

function Rect:__tostring()
    return ("Rect(x: %d, y: %d, w: %d, h: %d)"):format(self.position.x, self.position.y, self.size.width, self.size.height)
end

return Rect