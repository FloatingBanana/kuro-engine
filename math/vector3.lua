local Vector2 = require "engine.math.vector2"
local CStruct = require "engine.cstruct"
local Vector3 = CStruct("vector3", [[
    float x, y, z;
]])

local double_epsilon = 4.94065645841247E-324

-- See [engine/vector2.lua] for explanation
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end

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
        return math.sqrt(self.lengthSquared)
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

function Vector3:__tostring()
    return ("Vector3(x: %f, y: %f, z: %f)"):format(self.x, self.y, self.z)
end

---------------------
------ Methods ------
---------------------

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

function Vector3:negate()
    self.x = -self.x
    self.y = -self.y
    self.z = -self.z

    return self
end

function Vector3:normalize()
    self:divide(self.length)

    return self
end

function Vector3:invert()
    self.x = 1 / self.x
    self.y = 1 / self.y
    self.z = 1 / self.z

    return self
end


-- domo same desu

function Vector3:reflect(normal)
    local dot = Vector3.dot(self, normal)

    self.x = self.x - (2 * normal.x) * dot;
    self.y = self.y - (2 * normal.y) * dot;
    self.z = self.z - (2 * normal.z) * dot;

    return self
end

function Vector3:clamp(min, max)
    self.x = Lume.clamp(self.x, min.x, max.x)
    self.y = Lume.clamp(self.y, min.y, max.y)
    self.z = Lume.clamp(self.z, min.z, max.z)

    return self
end

function Vector3:transform(value)
    if value.typename == "quaternion" then
        local x = 2 * (value.y * self.z - value.z * self.y);
        local y = 2 * (value.z * self.x - value.x * self.z);
        local z = 2 * (value.x * self.y - value.y * self.x);

        self.x = self.x + x * value.w + (value.y * z - value.z * y);
        self.y = self.y + y * value.w + (value.z * x - value.x * z);
        self.z = self.z + z * value.w + (value.x * y - value.y * x);
    else
        -- Matrix
        self.x = (self.x * value.m11) + (self.y * value.m21) + (self.z * value.m31) + value.m41;
        self.y = (self.x * value.m12) + (self.y * value.m22) + (self.z * value.m32) + value.m42;
        self.z = (self.x * value.m13) + (self.y * value.m23) + (self.z * value.m33) + value.m43;
    end

    return self
end

function Vector3:worldToScreen(screenMatrix, screenSize, minDepth, maxDepth)
	local a = (((self.x * screenMatrix.m14) + (self.y * screenMatrix.m24)) + (self.z * screenMatrix.m34)) + screenMatrix.m44

    self:transform(screenMatrix)

    if math.abs(a-1) > double_epsilon then
        self:divide(a)
    end

    self.x = (((self.x + 1) * 0.5) * screenSize.width)
	self.y = (((-self.y + 1) * 0.5) * screenSize.height)
	self.z = (self.z * (maxDepth - minDepth)) + minDepth;

    return self;
end

function Vector3:screenToWorld(screenMatrix, screenSize, minDepth, maxDepth)
    self.x = (((self.x) / (screenSize.width)) * 2) - 1
	self.y = -((((self.y) / (screenSize.height)) * 2) - 1)
	self.z = (self.z - minDepth) / (maxDepth - minDepth)

    local mat = screenMatrix.inverse
	local a = (((self.x * mat.m14) + (self.y * mat.m24)) + (self.z * mat.m34)) + mat.m44;

    self:transform(mat)

	if math.abs(a-1) > double_epsilon then
        self:divide(a)
    end

	return self;
end

function Vector3:floor()
    self.x = math.floor(self.x)
    self.y = math.floor(self.y)
    self.z = math.floor(self.z)

    return self
end

function Vector3:ceil()
    self.x = math.ceil(self.x)
    self.y = math.ceil(self.y)
    self.z = math.ceil(self.z)

    return self
end

function Vector3:isNan()
    return self ~= self
end

function Vector3:clone()
    return Vector3(self.x, self.y, self.z)
end

function Vector3:split()
    return self.x, self.y, self.z
end

----------------------------
----- Static functions -----
----------------------------

function Vector3.dot(v1, v2)
    return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
end

function Vector3.cross(v1, v2)
    return Vector3(
          v1.y * v2.z - v2.y * v1.z,
        -(v1.x * v2.z - v2.x * v1.z),
          v1.x * v2.y - v2.x * v1.y
    )
end

function Vector3.distanceSquared(v1, v2)
    local x = v2.x - v1.x
    local y = v2.y - v1.y
    local z = v2.z - v1.z
    return x*x + y*y + z*z
end

function Vector3.distance(v1, v2)
    return math.sqrt(Vector3.distanceSquared(v1, v2))
end

function Vector3.min(v1, v2)
    return Vector3(
        math.min(v1.x, v2.x),
        math.min(v1.y, v2.y),
        math.min(v1.z, v2.z)
    )
end

function Vector3.max(v1, v2)
    return Vector3(
        math.max(v1.x, v2.x),
        math.max(v1.y, v2.y),
        math.max(v1.z, v2.z)
    )
end

return Vector3