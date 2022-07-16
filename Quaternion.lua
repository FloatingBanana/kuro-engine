-- Borrowed from https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Quaternion.cs

local CStruct = require "engine.cstruct"
local Quaternion = CStruct("quaternion", [[
	double x, y, z, w;
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

	if key == "lengthSquared" then
		return (self.x * self.x) + (self.y * self.y) + (self.z * self.z) + (self.w * self.w)
	end

	if key == "length" then
		return math.sqrt(self.lengthSquared)
	end
end

function Quaternion:__add(other)
	return self:clone():add(other)
end

function Quaternion:__sub(other)
	return self:clone():subtract(other)
end

function Quaternion:__mult(other)
	return self:clone():multiply(other)
end

function Quaternion:__div(other)
	return self:clone():divide(other)
end

function Quaternion:__eq(other)
	return self.x == other.x and
		   self.y == other.y and
		   self.z == other.z and
		   self.w == other.w
end

--------------------
------ Methods------
--------------------

function Quaternion:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.z = self.z + other.z
	self.w = self.w + other.w

	return self
end

function Quaternion:subtract(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	self.z = self.z - other.z
	self.w = self.w - other.w

	return self
end

function Quaternion:multiply(other)
	if type(other) == "number" then
		self.x = self.x * other
		self.y = self.y * other
		self.z = self.z * other
		self.w = self.w * other
	else
		local value1 = (self.y * other.z) - (self.z * other.y)
		local value2 = (self.z * other.x) - (self.x * other.z)
		local value3 = (self.x * other.y) - (self.y * other.x)
		local value4 = (self.x * other.x) + (self.y * other.y) + (self.z * other.z)

		self.x = (self.x * other.w) + (other.x * self.w) + value1
		self.y = (self.y * other.w) + (other.y * self.w) + value2
		self.z = (self.z * other.w) + (other.z * self.w) + value3
		self.w = (self.w * other.w) - value4
	end

	return self
end

function Quaternion:divide(other)
	if type(other) == "number" then
		self.x = self.x / other.x
		self.y = self.y / other.y
		self.z = self.z / other.z
		self.w = self.w / other.w
	else
		-- yeah, IDK either...
		local invLength = 1 / other.length
		local otX = -other.x * invLength
		local otY = -other.y * invLength
		local otZ = -other.z * invLength
		local otW = other.w * invLength
		local value1 = (self.y * otZ) - (self.z * otY)
		local value2 = (self.z * otX) - (self.x * otZ)
		local value3 = (self.x * otY) - (self.y * otX)
		local value4 = (self.x * otX) + (self.y * otY) + (self.z * otZ)

		self.x = (self.x * otW) + (otX * self.w) + value1
		self.y = (self.y * otW) + (otY * self.w) + value2
		self.z = (self.z * otW) + (otZ * self.w) + value3
		self.w = (self.w * otW) - value4
	end

	return self
end

function Quaternion:normalize()
	local invLength = 1 / self.length
	self.x = self.x * invLength
	self.y = self.y * invLength
	self.z = self.z * invLength
	self.w = self.w * invLength

	return self
end

function Quaternion:clone()
	return Quaternion(self.x, self.y, self.z, self.w)
end

--------------------------------
------ Static functions---------
--------------------------------

function Quaternion.identity()
	return Quaternion(0, 0, 0, 1)
end

function Quaternion.lerp(q1, q2, progress)
	local invAmount = 1 - progress
	local quaternion = Quaternion()
	local dot = Quaternion.dot(q1, q2)

	if dot >= 0 then
		quaternion.x = (invAmount * q1.x) + (progress * q2.x)
		quaternion.y = (invAmount * q1.y) + (progress * q2.y)
		quaternion.z = (invAmount * q1.z) + (progress * q2.z)
		quaternion.w = (invAmount * q1.w) + (progress * q2.w)
	else
		quaternion.x = (invAmount * q1.x) - (progress * q2.x)
		quaternion.y = (invAmount * q1.y) - (progress * q2.y)
		quaternion.z = (invAmount * q1.z) - (progress * q2.z)
		quaternion.w = (invAmount * q1.w) - (progress * q2.w)
	end

	return quaternion:normalized()
end

function Quaternion.slerp(q1, q2, amount)
	local num2, num3
	local opposite = false
	local cosTheta = Quaternion.dot(q1, q2)

	if cosTheta < 0 then
		opposite = true
		cosTheta = -cosTheta
	end

	if cosTheta > 0.999999 then
		num3 = 1 - amount
		num2 = opposite and -amount or amount
	else
		local angle = math.acos(cosTheta)
		local num6 = 1 / math.sin(angle)

		num3 = math.sin((1 - amount) * angle) * num6
		num2 = opposite and (-math.sin(amount * angle) * num6) or (math.sin(amount * angle) * num6)
	end

	return Quaternion(
		(num3 * q1.x) + (num2 * q2.x),
		(num3 * q1.y) + (num2 * q2.y),
		(num3 * q1.z) + (num2 * q2.z),
		(num3 * q1.w) + (num2 * q2.w)
	)
end

function Quaternion.dot(v1, v2)
	return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z) + (v1.w * v2.w)
end

function Quaternion.createFromAxisAngle(axis, angle)
	local half = angle * 0.5
	local sin = math.sin(half)
	local cos = math.cos(half)

	return Quaternion(axis.x * sin, axis.y * sin, axis.z * sin, cos)
end

function Quaternion.createFromYawPitchRoll(yaw, pitch, roll)
	local halfRoll = roll * 0.5
	local halfPitch = pitch * 0.5
	local halfYaw = yaw * 0.5

	local sinRoll = math.sin(halfRoll)
	local cosRoll = math.cos(halfRoll)
	local sinPitch = math.sin(halfPitch)
	local cosPitch = math.cos(halfPitch)
	local sinYaw = math.sin(halfYaw)
	local cosYaw = math.cos(halfYaw)

	return Quaternion(
		(cosYaw * sinPitch * cosRoll) + (sinYaw * cosPitch * sinRoll),
		(sinYaw * cosPitch * cosRoll) - (cosYaw * sinPitch * sinRoll),
		(cosYaw * cosPitch * sinRoll) - (sinYaw * sinPitch * cosRoll),
		(cosYaw * cosPitch * cosRoll) + (sinYaw * sinPitch * sinRoll)
	)
end

function Quaternion.createFromRotationMatrix(mat)
    local scale = mat.m11 + mat.m22 + mat.m33;

	if (scale > 0) then
        local sqrt = math.sqrt(scale + 1);
        local half = 0.5 / sqrt;

		return Quaternion(
			(mat.m23 - mat.m32) * half,
	    	(mat.m31 - mat.m13) * half,
	    	(mat.m12 - mat.m21) * half,
	    	sqrt * 0.5
		)
	end

	if ((mat.m11 >= mat.m22) and (mat.m11 >= mat.m33)) then
        local sqrt = math.sqrt(1 + mat.m11 - mat.m22 - mat.m33);
        local half = 0.5 / sqrt;

	    return Quaternion(
			0.5 * sqrt,
	    	(mat.m12 + mat.m21) * half,
	    	(mat.m13 + mat.m31) * half,
	    	(mat.m23 - mat.m32) * half
		)
	end

	if (mat.m22 > mat.m33) then
        local sqrt = math.sqrt(1 + mat.m22 - mat.m11 - mat.m33);
        local half = 0.5 / sqrt;

		return Quaternion(
			(mat.m21 + mat.m12) * half,
	    	0.5 * sqrt,
	    	(mat.m32 + mat.m23) * half,
	    	(mat.m31 - mat.m13) * half
		)
	end
    local sqrt = math.sqrt(1 + mat.m33 - mat.m11 - mat.m22);
	local half = 0.5 / sqrt;

	return Quaternion(
		(mat.m31 + mat.m13) * half,
		(mat.m32 + mat.m23) * half,
		0.5 * sqrt,
		(mat.m12 - mat.m21) * half
	)
end

return Quaternion