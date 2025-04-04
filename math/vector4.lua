local Lume    = require "engine.3rdparty.lume"
local Vector2 = require "engine.math.vector2"
local Vector3 = require "engine.math.vector3"
local CStruct = require "engine.misc.cstruct"
local abs, sqrt, floor, ceil, min, max = math.abs, math.sqrt, math.floor, math.ceil, math.min, math.max

local double_epsilon = 4.94065645841247E-324

-- See [engine/vector2.lua] for explanation
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end


---
--- A 4D vector that can represent a position, box, color, etc
---
--- @class Vector4: CStruct
---
--- @field length number: The magnitude of this vector
--- @field lengthSquared number: The squared magnitude of this vector
--- @field normalized Vector3: Gets a copy of this vector with magnitude of 1
--- @field inverse Vector3: Gets a copy of this vector with the components inverted (i.e `1 / value`)
--- @field x number: X axis of the vector
--- @field y number: Y axis of the vector
--- @field z number: Z axis of the vector
--- @field w number: W axis of the vector
---
--- @field left number: Alias to X
--- @field top number: Alias to Y
--- @field right number: Alias to Z
--- @field bottom number: Alias to W
--- @field x1 number: Alias to X
--- @field y1 number: Alias to Y
--- @field x2 number: Alias to Z
--- @field y2 number: Alias to W
--- @field red number: Alias to X
--- @field green number: Alias to Y
--- @field blue number: Alias to Z
--- @field alpha number: Alias to W
--- @field r number: Alias to X
--- @field g number: Alias to Y
--- @field b number: Alias to Z
--- @field a number: Alias to W
---
--- @field width number: returns `right - left`
--- @field height number: returns `bottom - top`
--- @field topleft Vector2: returns `Vector2(left, top)`
--- @field bottomright Vector2: returns `Vector2(right, bottom)`
---
--- @operator call: Vector4
--- @operator add: Vector4
--- @operator sub: Vector4
--- @operator mul: Vector4
--- @operator div: Vector4
--- @operator unm: Vector4
local Vector4 = CStruct("Vector4", [[
    float x, y, z, w;
]])

function Vector4:new(x, y, z, w)
    self.x = x or 0
    self.y = y or x or 0
    self.z = z or x or 0
    self.w = w or x or 0
end

-----------------------
----- Metamethods -----
-----------------------

local aliases = {
    left   = "x", red   = "x", r = "x", x1 = "x",
    top    = "y", green = "y", g = "y", y1 = "y",
    right  = "z", blue  = "z", b = "z", x2 = "z",
    bottom = "w", alpha = "w", a = "w", y2 = "w"
}

function Vector4:__index(key)
    if aliases[key] then
        return self[aliases[key]]
    end

    if key == "lengthSquared" then
        return self.x*self.x + self.y*self.y + self.z*self.z + self.w*self.w
    end

    if key == "length" then
        return sqrt(self.lengthSquared)
    end

    if key == "width" then
        return self.right - self.left
    end

    if key == "height" then
        return self.bottom - self.top
    end

    if key == "topleft" then
        return Vector2(self.left, self.top)
    end

    if key == "bottomright" then
        return Vector2(self.right, self.bottom)
    end

    if key == "normalized" then
        return self:clone():normalize()
    end

    if key == "inverse" then
        return self:clone():invert()
    end

    if not key:match("[^xyzw]") then
        local ax1, ax2, ax3, ax4 = key:sub(1,1), key:sub(2,2), key:sub(3,3), key:sub(4,4)

        if #key == 2 then
            return Vector2(ax1, ax2)
        elseif #key == 3 then
            return Vector3(ax1, ax2, ax3)
        elseif #key == 4 then
            return Vector4(ax1, ax2, ax3, ax4)
        end
    end

    return Vector4[key]
end

function Vector4:__newindex(key, value)
    if aliases[key] then
        self[aliases[key]] = value
        return
    end

    if key == "width" then
        self.right = self.left + value
        return
    end

    if key == "height" then
        self.bottom = self.top + value
        return
    end

    rawset(self, key, value)
end

function Vector4:__add(other)
    self, other = commutative_reorder(self, other)
    return self:clone():add(other)
end

function Vector4:__sub(other)
    if type(self) == "number" then
        return Vector4(self - other.x, self - other.y, self - other.z, self - other.w)
    end
    return self:clone():subtract(other)
end

function Vector4:__mul(other)
    self, other = commutative_reorder(self, other)
    return self:clone():multiply(other)
end

function Vector4:__div(other)
    if type(self) == "number" then
        return Vector4(self / other.x, self / other.y, self / other.z, self / other.w)
    end
    return self:clone():divide(other)
end

function Vector4:__unm()
    return self:clone():negate()
end

function Vector4:__eq(other)
    return self.x == other.x and
           self.y == other.y and
           self.z == other.z
end

function Vector4:__lt(other)
    return self.x < other.x or
           self.y < other.y or
           self.z < other.z or
           self.w < other.w
end

function Vector4:__le(other)
    return self.x <= other.x or
           self.y <= other.y or
           self.z <= other.z or
           self.w <= other.w
end

function Vector4:__tostring()
    return ("Vector4(x: %f, y: %f, z: %f, w: %f)"):format(self.x, self.y, self.z, self.w)
end

---------------------
------ Methods ------
---------------------


--- Peforms an addition operation on this vector (`self + other`)
--- @param other Vector4 | number: The right hand operand
--- @return Vector4: This vector
function Vector4:add(other)
    if type(other) == "number" then
        self.x = self.x + other
        self.y = self.y + other
        self.z = self.z + other
        self.w = self.w + other
    else
        self.x = self.x + other.x
        self.y = self.y + other.y
        self.z = self.z + other.z
        self.w = self.w + other.w
    end

    return self
end


--- Peforms a subtraction operation on this vector (`self - other`)
--- @param other Vector4 | number: The right hand operand
--- @return Vector4: This vector
function Vector4:subtract(other)
    if type(other) == "number" then
        self.x = self.x - other
        self.y = self.y - other
        self.z = self.z - other
        self.w = self.w - other
    else
        self.x = self.x - other.x
        self.y = self.y - other.y
        self.z = self.z - other.z
        self.w = self.w - other.w
    end

    return self
end


--- Peforms a multiplication operation on this vector (`self * other`)
--- @param other Vector4 | Matrix4 | number: The right hand operand
--- @return Vector4: This vector
function Vector4:multiply(other)
    if type(other) == "number" then
        self.x = self.x * other
        self.y = self.y * other
        self.z = self.z * other
        self.w = self.w * other
    elseif other.typename == "Matrix4" then
        local x = self.x * other.m11 + self.y * other.m21 + self.z * other.m31 + self.w * other.m41
        local y = self.x * other.m12 + self.y * other.m22 + self.z * other.m32 + self.w * other.m42
        local z = self.x * other.m13 + self.y * other.m23 + self.z * other.m33 + self.w * other.m43
        local w = self.x * other.m14 + self.y * other.m24 + self.z * other.m34 + self.w * other.m44

        self:new(x, y, z, w)
    else
        self.x = self.x * other.x
        self.y = self.y * other.y
        self.z = self.z * other.z
        self.w = self.w * other.w
    end

    return self
end


--- Peforms a division operation on this vector (`self / other`)
--- @param other Vector4 | number: The right hand operand
--- @return Vector4: This vector
function Vector4:divide(other)
    if type(other) == "number" then
        self:multiply(1 / other)
    else
        self.x = self.x / other.x
        self.y = self.y / other.y
        self.z = self.z / other.z
        self.w = self.w / other.w
    end

    return self
end


--- Negates all components of this vector
--- @return Vector4: This vector
function Vector4:negate()
    self.x = -self.x
    self.y = -self.y
    self.z = -self.z
    self.w = -self.w

    return self
end


--- Make this vector have a magnitude of 1
--- @return Vector4: This vector
function Vector4:normalize()
    self:divide(self.length)

    return self
end


--- Invert (i.e make `1 / value`) all components of this vector
--- @return Vector4: This vector
function Vector4:invert()
    self.x = 1 / self.x
    self.y = 1 / self.y
    self.z = 1 / self.z
    self.w = 1 / self.w

    return self
end


--- Clamp this vector's component between `min` and `max`
--- @param vmin Vector4: Minimum value
--- @param vmax Vector4: Maximum value
--- @return Vector4: This vector
function Vector4:clamp(vmin, vmax)
    self.x = Lume.clamp(self.x, vmin.x, vmax.x)
    self.y = Lume.clamp(self.y, vmin.y, vmax.y)
    self.z = Lume.clamp(self.z, vmin.z, vmax.z)

    return self
end

--- Rounds down this vector's components
--- @return Vector4: This vector
function Vector4:floor()
    self.x = floor(self.x)
    self.y = floor(self.y)
    self.z = floor(self.z)

    return self
end


--- Rounds up this vector's components
--- @return Vector4: This vector
function Vector4:ceil()
    self.x = ceil(self.x)
    self.y = ceil(self.y)
    self.z = ceil(self.z)

    return self
end


--- Makes all components of this vector positive
--- @return Vector4: This vector
function Vector4:abs()
    self.x = abs(self.x)
    self.y = abs(self.y)
    self.z = abs(self.z)
    self.w = abs(self.w)

    return self
end


--- Checks if any of the components is equal to `Nan`
--- @return boolean
function Vector4:isNan()
    return self ~= self
end


--- Creates a new vector with the same component values of this one
--- @return Vector4: The new vector
function Vector4:clone()
    return Vector4(self.x, self.y, self.z, self.w)
end


--- Deconstruct this vector into individual values
--- @return number X, number Y, number Z, number W
function Vector4:split()
    return self.x, self.y, self.z, self.w
end

----------------------------
----- Static functions -----
----------------------------


--- Peforms a linear interpolation between two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: the second vector
--- @param t number: The interpolation progress between 0 and 1
--- @return Vector4: Result
function Vector4.Lerp(v1, v2, t)
    return (v1 * (1-t)):add(v2 * t)
end


--- Calculates the dot product between two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: the second vector
--- @return number: Result
function Vector4.Dot(v1, v2)
    return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z + v1.w*v2.w
end


--- Calculates the squared distance between two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: the second vector
--- @return number: The resulting distance
function Vector4.DistanceSquared(v1, v2)
    local x = v2.x - v1.x
    local y = v2.y - v1.y
    local z = v2.z - v1.z
    local w = v2.w - v1.w
    return x*x + y*y + z*z + w*w
end


--- Calculates the distance between two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: the second vector
--- @return number: The resulting distance
function Vector4.Distance(v1, v2)
    return sqrt(Vector4.DistanceSquared(v1, v2))
end


--- Creates a vector with the minimum values of two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: The second vector
--- @return Vector4: The minimum vector
function Vector4.Min(v1, v2)
    return Vector4(
        min(v1.x, v2.x),
        min(v1.y, v2.y),
        min(v1.z, v2.z),
        min(v1.w, v2.w)
    )
end


-- Creates a vector with the maximum values of two vectors
--- @param v1 Vector4: The first vector
--- @param v2 Vector4: The second vector
--- @return Vector4: The maximum vector
function Vector4.Max(v1, v2)
    return Vector4(
        max(v1.x, v2.x),
        max(v1.y, v2.y),
        max(v1.z, v2.z),
        max(v1.w, v2.w)
    )
end

return Vector4