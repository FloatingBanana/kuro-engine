local Object = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Vector2 = require "engine.math.vector2"
local Utils   = require "engine.misc.utils"
local sin, cos, sqrt = math.sin, math.cos, math.sqrt

-- https://web.archive.org/web/20220127124628/https://orlandoaguilar.github.io/sh/spherical/harmonics/irradiance/map/2017/02/12/SphericalHarmonics.html
-- https://github.com/TheRealMJP/LowResRendering/blob/master/SampleFramework11/v1.01/Graphics/SH.cpp


---@class SH9Color: Object
---
---@field coefficients Vector3[]
---
---@operator add: SH9Color
---@operator mul: SH9Color
---
---@overload fun(...: Vector3): SH9Color
local SH = Object:extend("SH9Color")

function SH:new(...)
    self.coefficients = {}

	for i = 1, 9 do
		self.coefficients[i] = select(i, ...) or Vector3(0)
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

---@param other number|Vector3|SH9Color
---@return self
function SH:multiply(other)
	if type(other) == "number" or Utils.isType(other, Vector3) then
		for i = 1, 9 do
			self.coefficients[i] = self.coefficients[i]:multiply(other)
		end
	else
		for i = 1, 9 do
			self.coefficients[i] = self.coefficients[i]:multiply(other.coefficients[i])
		end
	end

	return self
end


---@param other number|Vector3|SH9Color
---@return self
function SH:add(other)
	if type(other) == "number" or Utils.isType(other, Vector3) then
		for i = 1, 9 do
			self.coefficients[i] = self.coefficients[i]:add(other)
		end
	else
		for i = 1, 9 do
			self.coefficients[i] = self.coefficients[i]:add(other.coefficients[i])
		end
	end

	return self
end


---@return Vector3, Vector3, Vector3, Vector3, Vector3, Vector3, Vector3, Vector3, Vector3
function SH:split()
	return
		self.coefficients[1],
		self.coefficients[2],
		self.coefficients[3],
		self.coefficients[4],
		self.coefficients[5],
		self.coefficients[6],
		self.coefficients[7],
		self.coefficients[8],
		self.coefficients[9]
end


---@return SH9Color
function SH:clone()
	return SH(self:split())
end



------------------------
--- Static functions ---
------------------------

---@param dir Vector3
---@return SH9Color
---@overload fun(dir: Vector3): SH9Color
function SH.ProjectDirection(dir)
	return SH(
    	Vector3(0.282095),
    	Vector3(0.488603 * dir.y),
    	Vector3(0.488603 * dir.z),
    	Vector3(0.488603 * dir.x),
    	Vector3(1.092548 * dir.x * dir.y),
    	Vector3(1.092548 * dir.y * dir.z),
    	Vector3(0.315392 * (3.0 * dir.z * dir.z - 1.0)),
    	Vector3(1.092548 * dir.x * dir.z),
    	Vector3(0.546274 * (dir.x * dir.x - dir.y * dir.y))
	)
end


---@param eqMap love.ImageData
---@return SH9Color
function SH.CreateFromEquirectangularMap(eqMap)
	local hf = math.pi / eqMap:getHeight()
	local wf = (2.0 * math.pi) / eqMap:getWidth()

    local weightSum = 0.0
    local result = SH()

	for y = 0, eqMap:getHeight()-1 do
		local phi = hf * y
		local sinPhi = sin(phi) * hf * wf

		for x = 0, eqMap:getWidth()-1 do
			local theta = wf * x
			local dir = Vector3(-cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi))

			local pixel = Vector3(eqMap:getPixel(x, y))
			local base = SH.ProjectDirection(dir, pixel):multiply(sinPhi)
			result:add(base)

			weightSum = weightSum + sinPhi
        end
    end

	return result:multiply(4.0 * math.pi / weightSum)
end


---@param cubeMapFaces love.ImageData[]|love.Canvas
---@return SH9Color
function SH.CreateFromCubeMap(cubeMapFaces)
	if Utils.isType(cubeMapFaces, "Canvas") then
		cubeMapFaces = {
			cubeMapFaces:newImageData(1),
			cubeMapFaces:newImageData(2),
			cubeMapFaces:newImageData(3),
			cubeMapFaces:newImageData(4),
			cubeMapFaces:newImageData(5),
			cubeMapFaces:newImageData(6),
		}
	end

	local size = Vector2(cubeMapFaces[1]:getDimensions())
    local weightSum = 0.0
    local result = SH()

	for y = 0, size.height-1 do
		for x = 0, size.width-1 do
			local uv = Vector2(x, y):add(0.5):divide(size):multiply(2):subtract(1)
			local temp = 1.0 + uv.lengthSquared
			local weight = 4.0 / (sqrt(temp) * temp)

			for face = 1, 6 do
                local sample = Vector3(cubeMapFaces[face]:getPixel(x, y))
				local u, v = uv.u, -uv.v

				local dir = (
					face == 1 and Vector3( 1, v, u) or
					face == 2 and Vector3(-1, v,-u) or
					face == 3 and Vector3( u, 1, v) or
					face == 4 and Vector3( u,-1,-v) or
					face == 5 and Vector3( u, v,-1) or
					face == 6 and Vector3(-u, v, 1)
				)

				local base = SH.ProjectDirection(dir:normalize()):multiply(sample * weight)
				result:add(base)

				weightSum = weightSum + weight
			end
		end
	end

    return result:multiply(4.0 * math.pi / weightSum)
end

return SH