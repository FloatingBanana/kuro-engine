local Object = require "engine.3rdparty.classic.classic"

-- https://web.archive.org/web/20220127124628/https://orlandoaguilar.github.io/sh/spherical/harmonics/irradiance/map/2017/02/12/SphericalHarmonics.html#expand

---@class SH9: Object
---
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number
---@field [5] number
---@field [6] number
---@field [7] number
---@field [8] number
---@field [9] number
---
---@operator add: SH9
---@operator mul: SH9
---
---@overload fun(...: number): SH9
local SH = Object:extend("SH9")

function SH:new(...)
	for i = 1, 9 do
		self[i] = select(i, ...) or 0
	end
end





-------------------
--- Metamethods ---
-------------------

---@private
function SH:__add(other)
	return self:clone():add(other)
end


---@private
function SH:__mul(other)
	return self:clone():multiply(other)
end




---------------
--- Methods ---
---------------

---@param other number|SH9
---@return self
function SH:multiply(other)
	if type(other) == "number" then
		for i = 1, 9 do
			self[i] = self[i] * other
		end
	else
		for i = 1, 9 do
			self[i] = self[i] * other[i]
		end
	end

	return self
end


---@param other number|SH9
---@return self
function SH:add(other)
	if type(other) == "number" then
		for i = 1, 9 do
			self[i] = self[i] + other
		end
	else
		for i = 1, 9 do
			self[i] = self[i] + other[i]
		end
	end

	return self
end


---@return number, number, number, number, number, number, number, number, number
function SH:split()
	return
		self[1],
		self[2],
		self[3],
		self[4],
		self[5],
		self[6],
		self[7],
		self[8],
		self[9]
end


---@return SH9
function SH:clone()
	return SH(self:split())
end



------------------------
--- Static functions ---
------------------------

---@param dir Vector3
---@return SH9
function SH.ProjectDirection(dir)
	return SH(
    	0.282095,
    	0.488603 * dir.y,
    	0.488603 * dir.z,
    	0.488603 * dir.x,
    	1.092548 * dir.x * dir.y,
    	1.092548 * dir.y * dir.z,
    	0.315392 * (3.0 * dir.z * dir.z - 1.0),
    	1.092548 * dir.x * dir.z,
    	0.546274 * (dir.x * dir.x - dir.y * dir.y)
	)
end


return SH