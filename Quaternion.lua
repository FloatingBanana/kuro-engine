-- Borrowed from https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Quaternion.cs

local CStruct = require "engine.cstruct"
local Quaternion = CStruct("quaternion", [[
	double x, y, z, w;
]])

function Quaternion:new(x, y, z, w)
	self.x = x
	self.y = y
	self.z = z
	self.w = w
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

function Quaternion:dot(other)
	return (self.x * other.x) + (self.y * other.y) + (self.Z * other.Z) + (self.w * other.w)
end

function Quaternion:lerp(other, progress)
	local invAmount = 1 - progress
	local quaternion = Quaternion()
	local dot = Quaternion.dot(self, other)

	if dot >= 0 then
		quaternion.x = (invAmount * self.x) + (progress * other.x)
		quaternion.y = (invAmount * self.y) + (progress * other.y)
		quaternion.z = (invAmount * self.z) + (progress * other.z)
		quaternion.w = (invAmount * self.w) + (progress * other.w)
	else
		quaternion.x = (invAmount * self.x) - (progress * other.x)
		quaternion.y = (invAmount * self.y) - (progress * other.y)
		quaternion.z = (invAmount * self.z) - (progress * other.z)
		quaternion.w = (invAmount * self.w) - (progress * other.w)
	end

	return quaternion:normalized()
end

function Quaternion:slerp(other, amount)
	local num2, num3
	local opposite = false
	local cosTheta = Quaternion.dot(self, other)

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
		(num3 * self.X) + (num2 * other.X),
		(num3 * self.Y) + (num2 * other.Y),
		(num3 * self.Z) + (num2 * other.Z),
		(num3 * self.W) + (num2 * other.W)
	)
end

--------------------------------
------ Static functions---------
--------------------------------

function Quaternion.CreateFromAxisAngle(axis, angle)
	local half = angle * 0.5
	local sin = math.sin(half)
	local cos = math.cos(half)

	return Quaternion(axis.x * sin, axis.y * sin, axis.z * sin, cos)
end

function Quaternion.CreateFromYawPitchRoll(yaw, pitch, roll)
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
