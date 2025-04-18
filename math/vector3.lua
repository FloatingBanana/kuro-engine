local Lume    = require "engine.3rdparty.lume"
local Vector2 = require "engine.math.vector2"
local Utils   = require "engine.misc.utils"
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
--- A 3D vector that can represent a position, direction, color, etc
---
--- @class Vector3: CStruct
---
--- @field length number: The magnitude of this vector
--- @field lengthSquared number: The squared magnitude of this vector
--- @field normalized Vector3: Gets a copy of this vector with magnitude of 1
--- @field inverse Vector3: Gets a copy of this vector with the components inverted (i.e `1 / value`)
--- @field x number: X axis of the vector
--- @field y number: Y axis of the vector
--- @field z number: Z axis of the vector
---
--- @field width number: Alias to X
--- @field height number: Alias to Y
--- @field depth number: Alias to Z
--- @field red number: Alias to X
--- @field green number: Alias to Y
--- @field blue number: Alias to Z
--- @field pitch number: Alias to X
--- @field yaw number: Alias to Y
--- @field roll number: Alias to Z
---
--- @operator call: Vector3
--- @operator add: Vector3
--- @operator sub: Vector3
--- @operator mul: Vector3
--- @operator div: Vector3
--- @operator unm: Vector3
local Vector3 = CStruct("Vector3", [[
    float x, y, z;
]])

function Vector3:new(x, y, z)
    self.x = x or 0
    self.y = y or x or 0
    self.z = z or x or 0
end

-----------------------
----- Metamethods -----
-----------------------

local aliases = {
    width  = "x", red   = "x", r = "x", pitch = "x",
    height = "y", green = "y", g = "y", yaw   = "y",
    depth  = "z", blue  = "z", b = "z", roll  = "z"
}

function Vector3:__index(key)
    if aliases[key] then
        return self[aliases[key]]
    end

    if key == "lengthSquared" then
        return self.x*self.x + self.y*self.y + self.z*self.z
    end

    if key == "length" then
        return sqrt(self.lengthSquared)
    end

    if key == "normalized" then
        return self:clone():normalize()
    end

    if key == "inverse" then
        return self:clone():invert()
    end

    if not key:match("[^xyz]") then
        local ax1, ax2, ax3 = key:sub(1,1), key:sub(2,2), key:sub(3,3)

        if #key == 2 then
            return Vector2(ax1, ax2)
        elseif #key == 3 then
            return Vector3(ax1, ax2, ax3)
        end
    end

    return Vector3[key]
end

function Vector3:__newindex(key, value)
    if aliases[key] then
        self[aliases[key]] = value
        return
    end

    rawset(self, key, value)
end

function Vector3:__add(other)
    self, other = commutative_reorder(self, other)
    return self:clone():add(other)
end

function Vector3:__sub(other)
    if type(self) == "number" then
        return Vector3(self - other.x, self - other.y, self - other.z)
    end
    return self:clone():subtract(other)
end

function Vector3:__mul(other)
    self, other = commutative_reorder(self, other)
    return self:clone():multiply(other)
end

function Vector3:__div(other)
    if type(self) == "number" then
        return Vector3(self / other.x, self / other.y, self / other.z)
    end
    return self:clone():divide(other)
end

function Vector3:__unm()
    return self:clone():negate()
end

function Vector3:__eq(other)
    return self.x == other.x and
           self.y == other.y and
           self.z == other.z
end

function Vector3:__lt(other)
    return self.x < other.x or
           self.y < other.y or
           self.z < other.z
end

function Vector3:__le(other)
    return self.x <= other.x or
           self.y <= other.y or
           self.z <= other.z
end

function Vector3:__tostring()
    return ("Vector3(x: %f, y: %f, z: %f)"):format(self.x, self.y, self.z)
end

---------------------
------ Methods ------
---------------------


--- Peforms an addition operation on this vector (`self + other`)
--- @param other Vector3 | number: The right hand operand
--- @return Vector3: This vector
function Vector3:add(other)
    if type(other) == "number" then
        self.x = self.x + other
        self.y = self.y + other
        self.z = self.z + other
    else
        self.x = self.x + other.x
        self.y = self.y + other.y
        self.z = self.z + other.z
    end

    return self
end


--- Peforms a subtraction operation on this vector (`self - other`)
--- @param other Vector3 | number: The right hand operand
--- @return Vector3: This vector
function Vector3:subtract(other)
    if type(other) == "number" then
        self.x = self.x - other
        self.y = self.y - other
        self.z = self.z - other
    else
        self.x = self.x - other.x
        self.y = self.y - other.y
        self.z = self.z - other.z
    end

    return self
end


--- Peforms a multiplication operation on this vector (`self * other`)
--- @param other Vector3 | number: The right hand operand
--- @return Vector3: This vector
function Vector3:multiply(other)
    if type(other) == "number" then
        self.x = self.x * other
        self.y = self.y * other
        self.z = self.z * other
    else
        self.x = self.x * other.x
        self.y = self.y * other.y
        self.z = self.z * other.z
    end

    return self
end


--- Peforms a division operation on this vector (`self / other`)
--- @param other Vector3 | number: The right hand operand
--- @return Vector3: This vector
function Vector3:divide(other)
    if type(other) == "number" then
        self:multiply(1 / other)
    else
        self.x = self.x / other.x
        self.y = self.y / other.y
        self.z = self.z / other.z
    end

    return self
end


--- Negates all components of this vector
--- @return Vector3: This vector
function Vector3:negate()
    self.x = -self.x
    self.y = -self.y
    self.z = -self.z

    return self
end


--- Make this vector have a magnitude of 1
--- @return Vector3: This vector
function Vector3:normalize()
    self:divide(self.length)

    return self
end


--- Invert (i.e make `1 / value`) all components of this vector
--- @return Vector3: This vector
function Vector3:invert()
    self.x = 1 / self.x
    self.y = 1 / self.y
    self.z = 1 / self.z

    return self
end


-- domo same desu

--- Reflect this vector along a `normal`
--- @param normal Vector3: Reflection normal
--- @return Vector3: This vector
function Vector3:reflect(normal)
    local dot = Vector3.Dot(self, normal)

    self.x = self.x - (2 * normal.x) * dot;
    self.y = self.y - (2 * normal.y) * dot;
    self.z = self.z - (2 * normal.z) * dot;

    return self
end


--- Clamp this vector's component between `min` and `max`
--- @param vmin Vector3: Minimum value
--- @param vmax Vector3: Maximum value
--- @return Vector3: This vector
function Vector3:clamp(vmin, vmax)
    self.x = Lume.clamp(self.x, vmin.x, vmax.x)
    self.y = Lume.clamp(self.y, vmin.y, vmax.y)
    self.z = Lume.clamp(self.z, vmin.z, vmax.z)

    return self
end


--- Transform this vector by a matrix or quaternion
--- @param value Matrix3 | Matrix4 | Quaternion: The transformation matrix or quaternion
--- @return Vector3: This vector
function Vector3:transform(value)
    if Utils.isType(value, "Quaternion") then
        local x = 2 * (value.y * self.z - value.z * self.y);
        local y = 2 * (value.z * self.x - value.x * self.z);
        local z = 2 * (value.x * self.y - value.y * self.x);

        self.x = self.x + x * value.w + (value.y * z - value.z * y);
        self.y = self.y + y * value.w + (value.z * x - value.x * z);
        self.z = self.z + z * value.w + (value.x * y - value.y * x);

    elseif Utils.isType(value, "Matrix3") then
        local x = (self.x * value.m11) + (self.y * value.m21) + (self.z * value.m31);
        local y = (self.x * value.m12) + (self.y * value.m22) + (self.z * value.m32);
        local z = (self.x * value.m13) + (self.y * value.m23) + (self.z * value.m33);

        self:new(x, y, z)

    elseif Utils.isType(value, "Matrix4") then
        local x = (self.x * value.m11) + (self.y * value.m21) + (self.z * value.m31) + value.m41;
        local y = (self.x * value.m12) + (self.y * value.m22) + (self.z * value.m32) + value.m42;
        local z = (self.x * value.m13) + (self.y * value.m23) + (self.z * value.m33) + value.m43;

        self:new(x, y, z)
    else
        error("Unsupported transformation type")
    end

    return self
end


--- Transform this vector to screen space
--- @param screenMatrix Matrix4: The full transformation matrix from current space to screen space
--- @param screenSize Vector2: The resolution of the screen
--- @param minDepth number: The smallest depth value allowed
--- @param maxDepth number: The greatest depht value allowed
--- @return Vector3: This vector
function Vector3:worldToScreen(screenMatrix, screenSize, minDepth, maxDepth)
	local w = self.x * screenMatrix.m14 + self.y * screenMatrix.m24 + self.z * screenMatrix.m34 + screenMatrix.m44

    self:transform(screenMatrix)
    self:divide(w == 0 and 1 or w)

    self.x = ( self.x * 0.5 + 0.5) * screenSize.width
    self.y = (-self.y * 0.5 + 0.5) * screenSize.height
	self.z = ( self.z * 0.5 + 0.5) * (maxDepth - minDepth) + minDepth;

    return self;
end


--- Transform this vector from screen space to another space
--- @param screenMatrix Matrix4: The full transformation matrix from screen space to the desired
--- @param screenSize Vector2: The resolution of the screen
--- @param minDepth number: The smallest depth value allowed
--- @param maxDepth number: The greatest depht value allowed
--- @return Vector3: This vector
function Vector3:screenToWorld(screenMatrix, screenSize, minDepth, maxDepth)
    self.x = (self.x / screenSize.width) * 2 - 1
	self.y = -(self.y / screenSize.height * 2 - 1)
	self.z = (self.z - minDepth) / (maxDepth - minDepth) * 2 - 1

    local mat = screenMatrix.inverse
	local w = self.x * mat.m14 + self.y * mat.m24 + self.z * mat.m34 + mat.m44;

    self:transform(mat)
    self:divide(w == 0 and 1 or w)

	return self;
end


--- Rounds down this vector's components
--- @return Vector3: This vector
function Vector3:floor()
    self.x = floor(self.x)
    self.y = floor(self.y)
    self.z = floor(self.z)

    return self
end


--- Rounds up this vector's components
--- @return Vector3: This vector
function Vector3:ceil()
    self.x = ceil(self.x)
    self.y = ceil(self.y)
    self.z = ceil(self.z)

    return self
end


--- Makes all components of this vector positive
--- @return Vector3: This vector
function Vector3:abs()
    self.x = abs(self.x)
    self.y = abs(self.y)
    self.z = abs(self.z)

    return self
end


--- Checks if any of the components is equal to `Nan`
--- @return boolean
function Vector3:isNan()
    return self ~= self
end


--- Creates a new vector with the same component values of this one
--- @return Vector3: The new vector
function Vector3:clone()
    return Vector3(self.x, self.y, self.z)
end


--- Deconstruct this vector into individual values
--- @return number X, number Y, number Z
function Vector3:split()
    return self.x, self.y, self.z
end

----------------------------
----- Static functions -----
----------------------------


--- Peforms a linear interpolation between two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: the second vector
--- @param t number: The interpolation progress between 0 and 1
--- @return Vector3: Result
function Vector3.Lerp(v1, v2, t)
    return (v1 * (1-t)):add(v2 * t)
end


--- Calculates the dot product between two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: the second vector
--- @return number: Result
function Vector3.Dot(v1, v2)
    return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
end


--- Calculates the cross product between two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: the second vector
--- @return Vector3: Result
function Vector3.Cross(v1, v2)
    return Vector3(
          v1.y * v2.z - v2.y * v1.z,
        -(v1.x * v2.z - v2.x * v1.z),
          v1.x * v2.y - v2.x * v1.y
    )
end


--- Calculates the squared distance between two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: the second vector
--- @return number: The resulting distance
function Vector3.DistanceSquared(v1, v2)
    local x = v2.x - v1.x
    local y = v2.y - v1.y
    local z = v2.z - v1.z
    return x*x + y*y + z*z
end


--- Calculates the distance between two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: the second vector
--- @return number: The resulting distance
function Vector3.Distance(v1, v2)
    return sqrt(Vector3.DistanceSquared(v1, v2))
end


--- Creates a vector with the minimum values of two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: The second vector
--- @return Vector3: The minimum vector
function Vector3.Min(v1, v2)
    return Vector3(
        min(v1.x, v2.x),
        min(v1.y, v2.y),
        min(v1.z, v2.z)
    )
end


-- Creates a vector with the maximum values of two vectors
--- @param v1 Vector3: The first vector
--- @param v2 Vector3: The second vector
--- @return Vector3: The maximum vector
function Vector3.Max(v1, v2)
    return Vector3(
        max(v1.x, v2.x),
        max(v1.y, v2.y),
        max(v1.z, v2.z)
    )
end

return Vector3