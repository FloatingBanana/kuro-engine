local CStruct = require "engine.cstruct"
local Vector2 = CStruct("vector2", [[
    float x, y;
]])

-- Helper function for overloads of commutative operations to ensure that the order
-- of the arguments will always be the same (first the object, then the number), so we
-- don't need to worry if the operation was done "object * number" or "number * object"
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end

function Vector2:new(x, y)
    self.x = x or 0
    self.y = y or x or 0
end

-----------------------
----- Metamethods -----
-----------------------

local aliases = {
    width  = "x", u = "x",
    height = "y", v = "y",
}

function Vector2:__index(key)
    if aliases[key] then
        return self[aliases[key]]
    end

    if key == "lengthSquared" then
        return self.x*self.x + self.y*self.y
    end

    if key == "length" then
        return math.sqrt(self.lengthSquared)
    end

    if key == "angle" then
        return math.atan2(self.y, self.x)
    end

    if key == "normalized" then
        return self:clone():normalize()
    end

    if key == "inverse" then
        return self:clone():invert()
    end

    if not key:match("[^xy]") then
        local ax1, ax2 = key:sub(1,1), key:sub(2,2)
        return Vector2(ax1, ax2)
    end

    return Vector2[key]
end

function Vector2:__newindex(key, value)
    if aliases[key] then
        self[aliases[key]] = value
        return
    end

    rawset(self, key, value)
end

function Vector2:__add(other)
    self, other = commutative_reorder(self, other)
    return self:clone():add(other)
end

function Vector2:__sub(other)
    if type(self) == "number" then
        return Vector2(self - other.x, self - other.y)
    end
    return self:clone():subtract(other)
end

function Vector2:__mul(other)
    self, other = commutative_reorder(self, other)
    return self:clone():multiply(other)
end

function Vector2:__div(other)
    if type(self) == "number" then
        return Vector2(self / other.x, self / other.y)
    end
    return self:clone():divide(other)
end

function Vector2:__unm()
    return self:clone():negate()
end

function Vector2:__eq(other)
    return self.x == other.x and
           self.y == other.y
end

function Vector2:__tostring()
    return ("Vector2(x: %f, y: %f)"):format(self.x, self.y)
end

---------------------
------ Methods ------
---------------------

function Vector2:add(other)
    if type(other) == "number" then
        self.x = self.x + other
        self.y = self.y + other
    else
        self.x = self.x + other.x
        self.y = self.y + other.y
    end

    return self
end

function Vector2:subtract(other)
    if type(other) == "number" then
        self.x = self.x - other
        self.y = self.y - other
    else
        self.x = self.x - other.x
        self.y = self.y - other.y
    end

    return self
end

function Vector2:multiply(other)
    if type(other) == "number" then
        self.x = self.x * other
        self.y = self.y * other
    else
        self.x = self.x * other.x
        self.y = self.y * other.y
    end

    return self
end

function Vector2:divide(other)
    if type(other) == "number" then
        self:multiply(1 / other)
    else
        self.x = self.x / other.x
        self.y = self.y / other.y
    end

    return self
end

function Vector2:negate()
    self.x = -self.x
    self.y = -self.y

    return self
end

function Vector2:normalize()
    self:divide(self.length)

    return self
end

function Vector2:invert()
    self.x = 1 / self.x
    self.y = 1 / self.y

    return self
end


-- domo same desu

function Vector2:reflect(normal)
    local dot = Vector2.dot(self, normal)

    self.x = self.x - (2 * normal.x) * dot;
    self.y = self.y - (2 * normal.y) * dot;

    return self
end

function Vector2:clamp(min, max)
    self.x = Lume.clamp(self.x, min.x, max.x)
    self.y = Lume.clamp(self.y, min.y, max.y)

    return self
end

function Vector2:setAngle(angle)
    local mag = self.length

    self.x = math.cos(angle) * mag
    self.y = math.sin(angle) * mag

    return self
end

function Vector2:rotateBy(angle)
    self:new(
        self.x * math.cos(angle) - self.y * math.sin(angle),
        self.x * math.sin(angle) + self.y * math.cos(angle)
    )

    return self
end

function Vector2:isNan()
    return self ~= self
end

function Vector2:clone()
    return Vector2(self.x, self.y)
end

function Vector2:split()
    return self.x, self.y
end

----------------------------
----- Static functions -----
----------------------------

function Vector2.dot(v1, v2)
    return v1.x*v2.x + v1.y*v2.y
end

function Vector2.createAngled(angle, magnitude)
    return Vector2(
          math.cos(angle) * magnitude,
          math.sin(angle) * magnitude
    )
end

function Vector2.distanceSquared(v1, v2)
    local x = v2.x - v1.x
    local y = v2.y - v1.y
    return x*x + y*y
end

function Vector2.distance(v1, v2)
    return math.sqrt(Vector2.distanceSquared(v1, v2))
end

function Vector2.min(v1, v2)
    return Vector2(
        math.min(v1.x, v2.x),
        math.min(v1.y, v2.y)
    )
end

function Vector2.max(v1, v2)
    return Vector2(
        math.max(v1.x, v2.x),
        math.max(v1.y, v2.y)
    )
end

return Vector2