local Lume    = require "engine.3rdparty.lume"
local CStruct = require "engine.misc.cstruct"
local sin, cos, atan2, sqrt, floor, ceil, min, max = math.sin, math.cos, math.atan2, math.sqrt, math.floor, math.ceil, math.min, math.max

-- Helper function for overloads of commutative operations to ensure that the order
-- of the arguments will always be the same (first the object, then the number), so we
-- don't need to worry if the operation was done "object * number" or "number * object"
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end

---
--- A 2D vector that can represent a position, direction, etc
---
--- @class Vector2: CStruct
---
--- @field length number: The magnitude of this vector
--- @field lengthSquared number: The squared magnitude of this vector
--- @field normalized Vector3: Gets a new vector with magnitude of 1 pointing to the same direction of this one
--- @field inverse Vector3: Gets a new vector with the components inverted (i.e `1 / value`)
--- @field angle number: The angle this vector is pointing at
--- @field x number: X axis of the vector
--- @field y number: Y axis of the vector
---
--- @field width number: Alias to X
--- @field height number: Alias to Y
--- @field u number: Alias to X
--- @field v number: Alias to Y
---
--- @operator call:Vector2
--- @operator add:Vector2
--- @operator sub:Vector2
--- @operator mul:Vector2
--- @operator div:Vector2
--- @operator unm:Vector2
local Vector2 = CStruct("vector2", [[
    float x, y;
]])

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
        return sqrt(self.lengthSquared)
    end

    if key == "angle" then
        return atan2(self.y, self.x)
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


--- Peforms an addition operation on this vector (`self + other`)
--- @param other Vector2 | number: The right hand operand
--- @return Vector2: This vector
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


--- Peforms a subtraction operation on this vector (`self - other`)
--- @param other Vector2 | number: The right hand operand
--- @return Vector2: This vector
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


--- Peforms a multiplication operation on this vector (`self * other`)
--- @param other Vector2 | number: The right hand operand
--- @return Vector2: This vector
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


--- Peforms a division operation on this vector (`self / other`)
--- @param other Vector2 | number: The right hand operand
--- @return Vector2: This vector
function Vector2:divide(other)
    if type(other) == "number" then
        self:multiply(1 / other)
    else
        self.x = self.x / other.x
        self.y = self.y / other.y
    end

    return self
end


--- Negates all components of this vector
--- @return Vector2: This vector
function Vector2:negate()
    self.x = -self.x
    self.y = -self.y

    return self
end


--- Make this vector have a magnitude of 1
--- @return Vector2: This vector
function Vector2:normalize()
    self:divide(self.length)

    return self
end


--- Invert (i.e make `1 / value`) all components of this vector
--- @return Vector2: This vector
function Vector2:invert()
    self.x = 1 / self.x
    self.y = 1 / self.y

    return self
end


-- domo same desu

--- Reflect this vector along a `normal`
--- @param normal Vector2: Reflection normal
--- @return Vector2: This vector
function Vector2:reflect(normal)
    local dot = Vector2.Dot(self, normal)

    self.x = self.x - (2 * normal.x) * dot;
    self.y = self.y - (2 * normal.y) * dot;

    return self
end


--- Clamp this vector's component between `min` and `max`
--- @param vmin Vector2: Minimum value
--- @param vmax Vector2: Maximum value
--- @return Vector2: This vector
function Vector2:clamp(vmin, vmax)
    self.x = Lume.clamp(self.x, vmin.x, vmax.x)
    self.y = Lume.clamp(self.y, vmin.y, vmax.y)

    return self
end


--- Make this vector point to the specified `angle`
--- @param angle number: The angle this vector will point at
--- @return Vector2: This vector
function Vector2:setAngle(angle)
    local mag = self.length

    self.x = cos(angle) * mag
    self.y = sin(angle) * mag

    return self
end


--- Rotate this vector relative to the current angle
--- @param angle number: The angle to be applied
--- @return Vector2: This vector
function Vector2:rotateBy(angle)
    local x, y = self.x, self.y

    self.x = x * cos(angle) - y * sin(angle)
    self.y = x * sin(angle) + y * cos(angle)

    return self
end


--- Rounds down this vector's components
--- @return Vector2: This vector
function Vector2:floor()
    self.x = floor(self.x)
    self.y = floor(self.y)

    return self
end


--- Rounds up this vector's components
--- @return Vector2: This vector
function Vector2:ceil()
    self.x = ceil(self.x)
    self.y = ceil(self.y)

    return self
end


--- Checks if any of the components is equal to `Nan`
--- @return boolean
function Vector2:isNan()
    return self ~= self
end


--- Creates a new vector with the same component values of this one
--- @return Vector2: The new vector
function Vector2:clone()
    return Vector2(self.x, self.y)
end


--- Deconstruct this vector into individual values
--- @return number X, number Y
function Vector2:split()
    return self.x, self.y
end

----------------------------
----- Static functions -----
----------------------------


--- Peforms a linear interpolation between two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: the second vector
--- @param t number: The interpolation progress between 0 and 1
--- @return Vector2: Result
function Vector2.Lerp(v1, v2, t)
    return (v1 * (1-t)):add(v2 * t)
end


--- Calculates the dot product between two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: the second vector
--- @return number: Result
function Vector2.Dot(v1, v2)
    return v1.x*v2.x + v1.y*v2.y
end


--- Creates a new vector with the specified angle and magnitude
--- @param angle number: The angle of vector
--- @param magnitude number: The magnitude of vector
--- @return Vector2: Result
function Vector2.CreateAngled(angle, magnitude)
    return Vector2(
          cos(angle) * magnitude,
          sin(angle) * magnitude
    )
end


--- Calculates the squared distance between two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: the second vector
--- @return number: The resulting distance
function Vector2.DistanceSquared(v1, v2)
    local x = v2.x - v1.x
    local y = v2.y - v1.y
    return x*x + y*y
end


--- Calculates the distance between two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: the second vector
--- @return number: The resulting distance
function Vector2.Distance(v1, v2)
    return sqrt(Vector2.DistanceSquared(v1, v2))
end


--- Creates a vector with the minimum values of two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: The second vector
--- @return Vector2: The minimum vector
function Vector2.Min(v1, v2)
    return Vector2(
        min(v1.x, v2.x),
        min(v1.y, v2.y)
    )
end


--- Creates a vector with the maximum values of two vectors
--- @param v1 Vector2: The first vector
--- @param v2 Vector2: The second vector
--- @return Vector2: The maximum vector
function Vector2.Max(v1, v2)
    return Vector2(
        max(v1.x, v2.x),
        max(v1.y, v2.y)
    )
end

return Vector2