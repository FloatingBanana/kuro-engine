local Vector3    = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local CStruct    = require "engine.misc.cstruct"
local cos, sin   = math.cos, math.sin

-- See [engine/vector2.lua] for explanation
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end


---
--- A right-handed 3x3 matrix. Mostly used to store 3D transformations.
---
--- @class Matrix3: CStruct
---
--- @field forward Vector3: The forward direction of this matrix (m31, m32, m33)
--- @field up Vector3: The up direction of this matrix (m21, m22, m23)
--- @field right Vector3: The right direction of this matrix (m11, m12, m13)
--- @field backward Vector3: The backward direction of this matrix (-m31, -m32, -m33)
--- @field down Vector3: The down direction of this matrix (-m21, -m22, -m23)
--- @field left Vector3: The left direction of this matrix (-m11, -m12, -m13)
---
--- @field scale Vector3: Gets the scaling factor of this matrix
--- @field rotation Quaternion: Gets the rotation factor of this matrix
--- @field transposed Matrix3: Gets a copy of this matrix with the components transposed
--- @field inverse Matrix3: Gets a copy of this matrix with the components inverted
--- @field m11 number
--- @field m12 number
--- @field m13 number
--- @field m21 number
--- @field m22 number
--- @field m23 number
--- @field m31 number
--- @field m32 number
--- @field m33 number
---
--- @operator call: Matrix3
--- @operator add: Matrix3
--- @operator sub: Matrix3
--- @operator mul: Matrix3
--- @operator div: Matrix3
--- @operator unm: Matrix3
--- @operator len: number
local Matrix3 = CStruct("Matrix3", [[
    float m11, m12, m13,
          m21, m22, m23,
          m31, m32, m33;
]])

function Matrix3:new(...)
    for i=1, 9 do
        self[i] = select(i, ...) or 0
    end
end

-----------------------
----- Metamethods -----
-----------------------

local numberIndices = {
    "m11", "m12", "m13",
    "m21", "m22", "m23",
    "m31", "m32", "m33",
}

function Matrix3:__index(key)
    if numberIndices[key] then
        return self[numberIndices[key]]
    end

    -- Vectors
    if key == "forward"     then return Vector3(self.m31, self.m32, self.m33) end
    if key == "up"          then return Vector3(self.m21, self.m22, self.m23) end
    if key == "right"       then return Vector3(self.m11, self.m12, self.m23) end

    -- Opposite vectors
    if key == "backward" then return self.forward:negate() end
    if key == "down"     then return self.up:negate()      end
    if key == "left"     then return self.right:negate()   end

    if key == "scale" then
        local xs = (self.m11 * self.m12 * self.m13 < 0) and -1 or 1
        local ys = (self.m21 * self.m22 * self.m23 < 0) and -1 or 1
        local zs = (self.m31 * self.m32 * self.m33 < 0) and -1 or 1

        return Vector3(
            xs * math.sqrt(self.m11 * self.m11 + self.m12 * self.m12 + self.m13 * self.m13),
            ys * math.sqrt(self.m21 * self.m21 + self.m22 * self.m22 + self.m23 * self.m23),
            zs * math.sqrt(self.m31 * self.m31 + self.m32 * self.m32 + self.m33 * self.m33)
        )
    end

    if key == "rotation" then
        local scale = self.scale
        local mat = Matrix3(
            self.m11 / scale.x, self.m12 / scale.x, self.m13 / scale.x,
            self.m21 / scale.y, self.m22 / scale.y, self.m23 / scale.y,
            self.m31 / scale.z, self.m32 / scale.z, self.m33 / scale.z
        )

        return Quaternion.CreateFromRotationMatrix(mat);
    end

    if key == "transposed" then
        return self:clone():transpose()
    end

    if key == "inverse" then
        return self:clone():invert()
    end

    return Matrix3[key]
end

function Matrix3:__newindex(key, value)
    if numberIndices[key] then
        self[numberIndices[key]] = value
        return
    end

    rawset(self, key, value)
end

function Matrix3:__add(value)
    return self:clone():add(value)
end

function Matrix3:__sub(value)
    return self:clone():subtract(value)
end

function Matrix3:__mul(value)
    self, value = commutative_reorder(self, value)
    return self:clone():multiply(value)
end

function Matrix3:__div(value)
    self, value = commutative_reorder(self, value)
    return self:clone():divide(value)
end

function Matrix3:__unm(value)
    return self:clone():negate(value)
end

function Matrix3:__eq(other)
    for i=1, 9 do
        if self[i] ~= other[i] then
            return false
        end
    end

    return true
end

function Matrix3:__len()
    return 9
end

function Matrix3:__tostring()
    return ("Matrix3x3(\n\t%03f, %03f, %03f,\n\t%03f, %03f, %03f,\n\t%03f, %03f, %03f,\n)"):format(self:split())
end

---------------------
------ Methods ------
---------------------


--- Peforms an addition operation on this matrix (`self + other`)
--- @param other Matrix3 | number: The right hand operand
--- @return Matrix3: This matrix
function Matrix3:add(other)
    for i=1, 9 do
        self[i] = self[i] + other[i]
    end

    return self
end


--- Peforms a subtraction operation on this matrix (`self - other`)
--- @param other Matrix3 | number: The right hand operand
--- @return Matrix3: This matrix
function Matrix3:subtract(other)
    for i=1, 9 do
        self[i] = self[i] - other[i]
    end

    return self
end


--- Peforms a multiplication operation on this matrix (`self * other`)
--- @param other Matrix3 | number: The right hand operand
--- @return Matrix3: This matrix
function Matrix3:multiply(other)
    if type(other) == "number" then
        for i=1, 9 do
            self[i] = self[i] * other
        end
    else
        self:new(
            (((self.m11 * other.m11) + (self.m12 * other.m21)) + (self.m13 * other.m31)),
            (((self.m11 * other.m12) + (self.m12 * other.m22)) + (self.m13 * other.m32)),
            (((self.m11 * other.m13) + (self.m12 * other.m23)) + (self.m13 * other.m33)),
            (((self.m21 * other.m11) + (self.m22 * other.m21)) + (self.m23 * other.m31)),
            (((self.m21 * other.m12) + (self.m22 * other.m22)) + (self.m23 * other.m32)),
            (((self.m21 * other.m13) + (self.m22 * other.m23)) + (self.m23 * other.m33)),
            (((self.m31 * other.m11) + (self.m32 * other.m21)) + (self.m33 * other.m31)),
            (((self.m31 * other.m12) + (self.m32 * other.m22)) + (self.m33 * other.m32)),
            (((self.m31 * other.m13) + (self.m32 * other.m23)) + (self.m33 * other.m33))
        )
    end

    return self
end


--- Peforms a division operation on this matrix (`self / other`)
--- @param other Matrix3 | number: The right hand operand
--- @return self: This matrix
function Matrix3:divide(other)
    if type(other) == "number"then
        self:multiply(1 / other)
    else
        for i=1, 9 do
            self[i] = self[i] / other[i]
        end
    end

    return self
end


--- Negates all components of this matrix
--- @return self: This matrix
function Matrix3:negate()
    for i=1, 9 do
        self[i] = -self[i]
    end

    return self
end


--- Swap the rows and colums of this matrix
--- @return Matrix3: This matrix
function Matrix3:transpose()
    -- Calling the raw constructor just assigns the arguments to the matrix
    self:new(
        self.m11,
        self.m21,
        self.m31,

        self.m12,
        self.m22,
        self.m32,

        self.m13,
        self.m23,
        self.m33
    )

    return self
end


--- Invert all components of this matrix
--- @return Matrix3: This matrix
function Matrix3:invert()
    local c0 = self.m22 * self.m33 - self.m23 * self.m32;
    local c1 = self.m23 * self.m31 - self.m21 * self.m33;
    local c2 = self.m21 * self.m32 - self.m22 * self.m31;
    local invMajor = 1 / (self.m11 * c0 + self.m12 * c1 + self.m13 * c2)

    self:new(
        c0, self.m13 * self.m32 - self.m12 * self.m33, self.m12 * self.m23 - self.m13 * self.m22,
        c1, self.m11 * self.m33 - self.m13 * self.m31, self.m13 * self.m21 - self.m11 * self.m23,
        c2, self.m12 * self.m31 - self.m11 * self.m32, self.m11 * self.m22 - self.m12 * self.m21
    )

    return self:multiply(invMajor)
end


--- Checks if the translation, scale and rotation can be extracted from this matrix
--- @return boolean: `true` if this matrix can be decomposed, `false` otherwise
function Matrix3:isDecomposable()
    local scale = self.scale
    return scale.x ~= 0 and scale.y ~= 0 and scale.z ~= 0
end


--- Extracts the translation, scale and rotation of this matrix
--- @return Vector3 Scale, Quaternion Rotation
function Matrix3:decompose()
    return self.scale, self.rotation;
end


--- Creates a new matrix with the same component values of this one
--- @return Matrix3: The new matrix
function Matrix3:clone()
    return Matrix3(self:split())
end


--- Deconstruct this matrix into individual values
--- @return number m11, number m12, number m13, number m21, number m22, number m23, number m31, number m32, number m33
function Matrix3:split()
	return self.m11, self.m12, self.m13,
           self.m21, self.m22, self.m23,
           self.m31, self.m32, self.m33
end

----------------------------
----- Static functions -----
----------------------------


--- Creates an identity matrix
--- @return Matrix3
function Matrix3.Identity()
    return Matrix3(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    )
end


---Creates a rotation matrix pointing to a direction
---@param forward Vector3
---@param up Vector3
---@return Matrix3
function Matrix3.CreateFromDirection(forward, up)
    local right = Vector3.Cross(up, forward):normalize()
    up = Vector3.Cross(forward, right)

    return Matrix3(
        right.x,
        right.y,
        right.z,
        up.x,
        up.y,
        up.z,
        forward.x,
        forward.y,
        forward.z
    )
end


--- Creates a matrix rotated by an `angle` around an `axis`
--- @param axis Vector3: The axis of rotation
--- @param angle number: The angle of rotation
--- @return Matrix3: Result
function Matrix3.CreateFromAxisAngle(axis, angle)
	local sinAngle = sin(angle)
    local cosAngle = cos(angle)
    local oneMinusCos = 1 - cosAngle
    local mat = Matrix3.Identity()

    mat.m11 = axis.x * axis.x * oneMinusCos + cosAngle
    mat.m12 = axis.x * axis.y * oneMinusCos - axis.z * sinAngle
    mat.m13 = axis.x * axis.z * oneMinusCos + axis.y * sinAngle

    mat.m21 = axis.y * axis.x * oneMinusCos + axis.z * sinAngle
    mat.m22 = axis.y * axis.y * oneMinusCos + cosAngle
    mat.m23 = axis.y * axis.z * oneMinusCos - axis.x * sinAngle

    mat.m31 = axis.z * axis.x * oneMinusCos - axis.y * sinAngle
    mat.m32 = axis.z * axis.y * oneMinusCos + axis.x * sinAngle
    mat.m33 = axis.z * axis.z * oneMinusCos + cosAngle

    return mat
end


--- Creates a rotation matrix with the equivalent yaw, pitch and roll
--- @param yaw number: Yaw around the Y axis
--- @param pitch number: Pitch around the X axis
--- @param roll number: Roll around the Z axis
--- @return Matrix3: Result
function Matrix3.CreateFromYawPitchRoll(yaw, pitch, roll)
    local sinYaw = sin(yaw)
    local sinPitch = sin(pitch)
    local sinRoll = sin(roll)
    local cosYaw = cos(yaw)
    local cosPitch = cos(pitch)
    local cosRoll = cos(roll)
    local mat = Matrix3.Identity()

    mat.m11 = cosYaw * cosPitch
    mat.m12 = cosYaw * sinPitch * sinRoll - sinYaw * cosRoll
    mat.m13 = cosYaw * sinPitch * cosRoll + sinYaw * sinRoll

    mat.m21 = sinYaw * cosPitch
    mat.m22 = sinYaw * sinPitch * sinRoll + cosYaw * cosRoll
    mat.m23 = sinYaw * sinPitch * cosRoll - cosYaw * sinRoll

    mat.m31 = -sinPitch
    mat.m32 = cosPitch * sinRoll
    mat.m33 = cosPitch * cosRoll

    return mat
end


--- Creates a rotation matrix from a Quaternion
--- @param quat Quaternion: The Quaternion representing the rotation
--- @return Matrix3: Result
function Matrix3.CreateFromQuaternion(quat)
    local xx = quat.x * quat.x;
	local yy = quat.y * quat.y;
	local zz = quat.z * quat.z;
	local xy = quat.x * quat.y;
	local zw = quat.z * quat.w;
	local zx = quat.z * quat.x;
	local yw = quat.y * quat.w;
	local yz = quat.y * quat.z;
	local xw = quat.x * quat.w;
    local mat = Matrix3.Identity()

    mat.m11 = 1 - (2 * (yy + zz))
    mat.m12 = 2 * (xy + zw)
	mat.m13 = 2 * (zx - yw)

	mat.m21 = 2 * (xy - zw)
	mat.m22 = 1 - (2 * (zz + xx))
	mat.m23 = 2 * (yz + xw)

    mat.m31 = 2 * (zx + yw)
	mat.m32 = 2 * (yz - xw)
	mat.m33 = 1 - (2 * (yy + xx))

    return mat
end


--- Extracts the rotantion and scale from a Matrix4
---@param mat Matrix4: The Matrix4 to extract from
---@return Matrix3: The resulting Matrix3
function Matrix3.CreateFromMatrix4(mat)
    return Matrix3(
        mat.m11, mat.m12, mat.m13,
        mat.m21, mat.m22, mat.m23,
        mat.m31, mat.m32, mat.m33
    )
end


--- Creates a scaling matrix
--- @param scale Vector3: The scale value on each axis
--- @return Matrix3: Result
function Matrix3.CreateScale(scale)
    local mat = Matrix3.Identity()

    mat.m11 = scale.width
    mat.m22 = scale.height
    mat.m33 = scale.depth

    return mat
end


return Matrix3
