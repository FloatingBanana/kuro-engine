-- Borrowed from https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Quaternion.cs

local CStruct = require "engine.misc.cstruct"
local Vector3 = require "engine.math.vector3"
local sin, cos, acos, sqrt = math.sin, math.cos, math.acos, math.sqrt

-- See [engine/vector2.lua] for explanation
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end


---
--- An object that represents a 3D rotation
---
--- @class Quaternion: CStruct
---
--- @field x number: The X axis of this quaternion
--- @field y number: The Y axis of this quaternion
--- @field z number: The Z axis of this quaternion
--- @field w number: The rotation component of this quaternion
--- @field normalized Quaternion: Gets a new, normalized version of this quaternion
--- @field conjugated Quaternion: Gets a new, conjugated version of this quaternion
--- @field inverted Quaternion: Gets a new quaternion facing the opposite direction of this one
--- @field euler Vector3: Get the angles of this quaternion in radians (pitch, yaw, roll)
--- @field length number: The magnitude of this quaternion
--- @field lengthSquared number: The squared magnitude of this quaternion
---
--- @operator call: Quaternion
--- @operator add: Quaternion
--- @operator sub: Quaternion
--- @operator mul: Quaternion
--- @operator div: Quaternion
local Quaternion = CStruct("Quaternion", [[
	float x, y, z, w;
]])


function Quaternion:new(x, y, z, w)
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
	self.w = w or 0
end

-----------------------
----- Metamethods -----
-----------------------

function Quaternion:__index(key)
	if key == "normailized" then
		return self:clone():normalize()
	end

	if key == "conjugated" then
		return self:clone():conjugate()
	end

	if key == "inverse" then
		return self:clone():invert()
	end

	if key == "euler" then
		local q2sqr = self.y * self.y
    	local t0 = -2.0 * (q2sqr + self.z * self.z) + 1.0
    	local t1 =  2.0 * (self.x * self.y + self.w * self.z)
    	local t2 = -2.0 * (self.x * self.z - self.w * self.y)
    	local t3 =  2.0 * (self.y * self.z + self.w * self.x)
    	local t4 = -2.0 * (self.x * self.x + q2sqr) + 1.0

    	t2 = t2 >  1.0 and  1.0 or t2
    	t2 = t2 < -1.0 and -1.0 or t2

		return Vector3(
    		math.asin(t2),
    		math.atan2(t3, t4),
    		math.atan2(t1, t0)
		)
	end

	if key == "lengthSquared" then
		return (self.x * self.x) + (self.y * self.y) + (self.z * self.z) + (self.w * self.w)
	end

	if key == "length" then
		return sqrt(self.lengthSquared)
	end

	return Quaternion[key]
end

function Quaternion:__add(other)
	return self:clone():add(other)
end

function Quaternion:__sub(other)
	return self:clone():subtract(other)
end

function Quaternion:__mul(other)
	self, other = commutative_reorder(self, other)
	return self:clone():multiply(other)
end

function Quaternion:__div(other)
	self, other = commutative_reorder(self, other)
	return self:clone():divide(other)
end

function Quaternion:__eq(other)
	return self.x == other.x and
		   self.y == other.y and
		   self.z == other.z and
		   self.w == other.w
end

function Quaternion:__tostring()
    return ("Quaternion(x: %f, y: %f, z: %f, w: %f)"):format(self.x, self.y, self.z, self.w)
end

--------------------
------ Methods------
--------------------


--- Peforms an addition operation on this quaternion (`self + other`)
--- @param other Quaternion: The right hand operand
--- @return Quaternion: This quaternion
function Quaternion:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.z = self.z + other.z
	self.w = self.w + other.w

	return self
end


--- Peforms a subtraction operation on this quaternion (`self - other`)
--- @param other Quaternion: The right hand operand
--- @return Quaternion: This quaternion
function Quaternion:subtract(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	self.z = self.z - other.z
	self.w = self.w - other.w

	return self
end


--- Peforms a multiplication operation on this quaternion (`self * other`)
--- @param other Quaternion | number: The right hand operand
--- @return Quaternion: This quaternion
function Quaternion:multiply(other)
	if type(other) == "number" then
		self.x = self.x * other
		self.y = self.y * other
		self.z = self.z * other
		self.w = self.w * other
	else
		local vx = (self.y * other.z) - (self.z * other.y)
		local vy = (self.z * other.x) - (self.x * other.z)
		local vz = (self.x * other.y) - (self.y * other.x)
		local vw = (self.x * other.x) + (self.y * other.y) + (self.z * other.z)

		self.x = (self.x * other.w) + (other.x * self.w) + vx
		self.y = (self.y * other.w) + (other.y * self.w) + vy
		self.z = (self.z * other.w) + (other.z * self.w) + vz
		self.w = (self.w * other.w) - vw
	end

	return self
end


--- Peforms a division operation on this quaternion (`self / other`)
--- @param other Quaternion | number: The right hand operand
--- @return Quaternion: This quaternion
function Quaternion:divide(other)
	if type(other) == "number" then
		self.x = self.x / other
		self.y = self.y / other
		self.z = self.z / other
		self.w = self.w / other
	else
		-- yeah, IDK either...
		local invoX, invoY, invoZ, invoW = other.inverted:split()
		local vx = (self.y * invoZ) - (self.z * invoY)
		local vy = (self.z * invoX) - (self.x * invoZ)
		local vz = (self.x * invoY) - (self.y * invoX)
		local vw = (self.x * invoX) + (self.y * invoY) + (self.z * invoZ)

		self.x = (self.x * invoW) + (invoX * self.w) + vx
		self.y = (self.y * invoW) + (invoY * self.w) + vy
		self.z = (self.z * invoW) + (invoZ * self.w) + vz
		self.w = (self.w * invoW) - vw
	end

	return self
end


--- Make this quaternion have a magnitude of 1
--- @return Quaternion: This quaternion
function Quaternion:normalize()
	self:multiply(1 / self.length)
	return self
end


--- Invert the imaginary part of this quaternion
--- @return Quaternion: This quaternion
function Quaternion:conjugate()
	self.x = -self.x
	self.y = -self.y
	self.z = -self.z

	return self
end

--- Rotate this quaternion to the opposite direction
--- @return Quaternion: This quaternion
function Quaternion:invert()
	return self:conjugate():normalize()
end

--- Creates a new quaternion with the same component values of this one
--- @return Quaternion: The new quaternion
function Quaternion:clone()
	return Quaternion(self.x, self.y, self.z, self.w)
end


--- Deconstruct this quaternion into individual values
--- @return number X, number Y, number Z, number W
function Quaternion:split()
	return self.x, self.y, self.z, self.w
end



--------------------------------
------ Static functions---------
--------------------------------

--- Creates a quaternion with components (X=0, Y=0, Z=0, W=1)
--- @return Quaternion
function Quaternion.Identity()
	return Quaternion(0, 0, 0, 1)
end


--- Creates a quaternion representing a linear interpolation between two quaternions
--- @param q1 Quaternion: Initial value
---	@param q2 Quaternion: Final value
---	@param progress number: Interpolation progress (0-1)
--- @return Quaternion: The interpolated quaternion
function Quaternion.Lerp(q1, q2, progress)
	local invProgress = 1 - progress
	local dot = Quaternion.Dot(q1, q2)
	local dir = (dot >= 0) and 1 or -1

	local quaternion = Quaternion(
		(invProgress * q1.x) + (progress * q2.x * dir),
		(invProgress * q1.y) + (progress * q2.y * dir),
		(invProgress * q1.z) + (progress * q2.z * dir),
		(invProgress * q1.w) + (progress * q2.w * dir)
	)

	return quaternion:normalize()
end


--- Creates a quaternion representing a spherical interpolation between two quaternions
--- @param q1 Quaternion: Initial value
---	@param q2 Quaternion: Final value
---	@param amount number: Interpolation progress (0-1)
--- @return Quaternion: The interpolated quaternion
function Quaternion.Slerp(q1, q2, amount)
	local progress = 0
	local invProgress = 0
	local opposite = false
	local cosTheta = Quaternion.Dot(q1, q2)

	if cosTheta < 0 then
		opposite = true
		cosTheta = -cosTheta
	end

	if cosTheta > 0.999999 then
		invProgress = 1 - amount
		progress = opposite and -amount or amount
	else
		local angle = acos(cosTheta)
		local invSin = 1 / sin(angle)

		invProgress = sin((1 - amount) * angle) * invSin
		progress = sin(amount * angle) * (opposite and -invSin or invSin)
	end

	return Quaternion(
		(invProgress * q1.x) + (progress * q2.x),
		(invProgress * q1.y) + (progress * q2.y),
		(invProgress * q1.z) + (progress * q2.z),
		(invProgress * q1.w) + (progress * q2.w)
	)
end


--- Calculates the dot product between two quaternions
--- @param v1 Quaternion: First quaternion
--- @param v2 Quaternion: Second quaternion
--- @return number: Result
function Quaternion.Dot(v1, v2)
	return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z) + (v1.w * v2.w)
end


--- Creates a quaternion rotated by an `angle` around an `axis` 
--- @param axis Vector3: The axis of rotation
--- @param angle number: The angle of rotation
--- @return Quaternion: Result
function Quaternion.CreateFromAxisAngle(axis, angle)
	local half = angle * 0.5
	local hsin = sin(half)

	return Quaternion(axis.x * hsin, axis.y * hsin, axis.z * hsin, cos(half))
end


--- Creates a quaternion with the equivalent yaw, pitch and roll
--- @param yaw number: Yaw around the Y axis
--- @param pitch number: Pitch around the X axis
--- @param roll number: Roll around the Z axis
--- @return Quaternion: Result
function Quaternion.CreateFromYawPitchRoll(yaw, pitch, roll)
	local halfRoll = roll * 0.5
	local halfPitch = pitch * 0.5
	local halfYaw = yaw * 0.5

	local sinRoll = sin(halfRoll)
	local cosRoll = cos(halfRoll)
	local sinPitch = sin(halfPitch)
	local cosPitch = cos(halfPitch)
	local sinYaw = sin(halfYaw)
	local cosYaw = cos(halfYaw)

	return Quaternion(
		(cosYaw * sinPitch * cosRoll) + (sinYaw * cosPitch * sinRoll),
		(sinYaw * cosPitch * cosRoll) - (cosYaw * sinPitch * sinRoll),
		(cosYaw * cosPitch * sinRoll) - (sinYaw * sinPitch * cosRoll),
		(cosYaw * cosPitch * cosRoll) + (sinYaw * sinPitch * sinRoll)
	)
end


--- Creates a quaternion from a Matrix
--- @param mat Matrix4|Matrix3: The rotation matrix
--- @return Quaternion: Result
function Quaternion.CreateFromRotationMatrix(mat)
    local scale = mat.m11 + mat.m22 + mat.m33;
	local quat = Quaternion()

	if scale > 0 then
        local scaleSqrt = sqrt(scale + 1);
        local half = 0.5 / scaleSqrt;

		quat.x = (mat.m23 - mat.m32) * half
	    quat.y = (mat.m31 - mat.m13) * half
	    quat.z = (mat.m12 - mat.m21) * half
	    quat.w = scaleSqrt * 0.5
	elseif (mat.m11 >= mat.m22) and (mat.m11 >= mat.m33) then
		local scaleSqrt = sqrt(1 + mat.m11 - mat.m22 - mat.m33);
		local half = 0.5 / scaleSqrt;

		quat.x = 0.5 * scaleSqrt
		quat.y = (mat.m12 + mat.m21) * half
	    quat.z = (mat.m13 + mat.m31) * half
		quat.w = (mat.m23 - mat.m32) * half
	elseif mat.m22 > mat.m33 then
		local scaleSqrt = sqrt(1 + mat.m22 - mat.m11 - mat.m33);
		local half = 0.5 / scaleSqrt;

		quat.x = (mat.m21 + mat.m12) * half
		quat.y = 0.5 * scaleSqrt
	    quat.z = (mat.m32 + mat.m23) * half
		quat.w = (mat.m31 - mat.m13) * half
	else
		local scaleSqrt = sqrt(1 + mat.m33 - mat.m11 - mat.m22);
		local half = 0.5 / scaleSqrt;

		quat.x = (mat.m31 + mat.m13) * half
		quat.y = (mat.m32 + mat.m23) * half
		quat.z = 0.5 * scaleSqrt
		quat.w = (mat.m12 - mat.m21) * half
	end

	return quat
end


---Creates a quaternion from a direction an up vector
---@param direction Vector3 Direction of the rotation
---@param forward Vector3 Forward direction relative to the deisired rotation
---@param up Vector3 Up direction relative to the deisired rotation
---@return Quaternion result
function Quaternion.CreateFromDirection(direction, forward, up)
	local rot1 = Quaternion.RotationBetweenVectors(forward, direction);
	local right = Vector3.Cross(direction, up)
	up = Vector3.Cross(right, direction);

	local newUp = Vector3(0,1,0):transform(rot1)
	local rot2 = Quaternion.RotationBetweenVectors(newUp, up)
	return rot2:multiply(rot1)
end


---@param forward Vector3
---@param direction Vector3
---@return Quaternion
function Quaternion.RotationBetweenVectors(forward, direction)
    forward = forward.normalized
    direction = direction.normalized

    local cosTheta = Vector3.Dot(forward, direction)

    if cosTheta < -1 + 0.001 then
        -- special case when vectors in opposite directions:
        -- there is no "ideal" rotation axis
        -- So guess one; any will do as long as it's perpendicular to start
        local axis = Vector3.Cross(Vector3(0.0, 0.0, 1.0), forward)

        if axis.lengthSquared * axis.lengthSquared < 0.01 then
            axis = Vector3.Cross(Vector3(1.0, 0.0, 0.0), forward)
		end

        axis:normalize()
        return Quaternion(axis.x, axis.y, axis.z, 0)
	end

    axis = Vector3.Cross(forward, direction)
    local s = sqrt((1 + cosTheta) * 2)
    local invs = 1 / s

    return Quaternion(
        axis.x * invs,
        axis.y * invs,
        axis.z * invs,
        s * 0.5
    )
end




--- Creates the dual part of a dual quaternion representating the translation
---@param rotation Quaternion
---@param pos Vector3
---@return Quaternion
function Quaternion.CreateDualQuaternionTranslation(rotation, pos)
	return Quaternion(
         0.5*( pos.x * rotation.w + pos.y * rotation.z - pos.z * rotation.y),
         0.5*(-pos.x * rotation.z + pos.y * rotation.w + pos.z * rotation.x),
         0.5*( pos.x * rotation.y - pos.y * rotation.x + pos.z * rotation.w),
		-0.5*( pos.x * rotation.x + pos.y * rotation.y + pos.z * rotation.z)
	)
end


return Quaternion