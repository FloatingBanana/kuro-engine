local CStruct = require "engine.cstruct"
local Rect = CStruct("Rect", [[
    brinevector position;
    brinevector size;
]])

local zero = Vector()

function Rect:new(pos, size)
    self.position = pos
    self.size = size
end

function Rect:isPointInside(pos)
    return Utils.vecAABB(self.position, self.size, pos, zero)
end

function Rect:testCollision(rect)
    return Utils.vecAABB(self.position, self.size, rect.position, rect.size)
end

function Rect:__index(key)
    if key == "topLeft" or key == "pos" then
        return self.position
    end

    if key == "center" then
        return self.position + (self.size / 2)
    end

    if key == "rightBottom" then
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

    if key == "rightBottom" then
        self.position = value - self.size
        return
    end

    rawset(self, key, value)
end

function Rect:__tostring()
    return ("Rect(x: %d, y: %d, w: %d, h: %d)"):format(self.position.x, self.position.y, self.size.x, self.size.y)
end

return Rect