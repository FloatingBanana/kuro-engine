local Vector3 = require "engine.vector3"
local Quaternion = require "engine.quaternion"
local CStruct = require "engine.cstruct"
local Matrix = CStruct("matrix", [[
    float m11, m12, m13, m14,
          m21, m22, m23, m24,
          m31, m32, m33, m34,
          m41, m42, m43, m44;
]])

function Matrix:new(...)
    for i=1, 16 do
        self[i] = select(i, ...) or 0
    end
end

-----------------------
----- Metamethods -----
-----------------------

local numberIndexes = {
    "m11", "m12", "m13", "m14",
    "m21", "m22", "m23", "m24",
    "m31", "m32", "m33", "m34",
    "m41", "m42", "m43", "m44",
}

function Matrix:__index(key)
    if numberIndexes[key] then
        return self[numberIndexes[key]]
    end

    -- Vectors
    if key == "translation" then return Vector3(self.m41, self.m42, self.m43) end
    if key == "backward"    then return Vector3(self.m31, self.m32, self.m33) end
    if key == "up"          then return Vector3(self.m21, self.m22, self.m23) end
    if key == "right"       then return Vector3(self.m11, self.m12, self.m23) end

    -- Opposite vectors
    if key == "backward" then return self.forward:negate() end
    if key == "down"     then return self.up:negate()      end
    if key == "left"     then return self.right:negate()   end

    return Matrix[key]
end

function Matrix:__newindex(key, value)
    if numberIndexes[key] then
        self[numberIndexes[key]] = value
        return
    end

    rawset(self, key, value)
end

function Matrix:__add(value)
    return self:clone():add(value)
end

function Matrix:__sub(value)
    return self:clone():sub(value)
end

function Matrix:__mult(value)
    return self:clone():mult(value)
end

function Matrix:__div(value)
    return self:clone():divide(value)
end

function Matrix:__unm(value)
    return self:clone():negate(value)
end

function Matrix:__eq(other)
    for i=1, 16 do
        if self[i] ~= other[i] then
            return false
        end
    end

    return true
end

function Matrix:__len()
    return 16
end

---------------------
------ Methods ------
---------------------

function Matrix:add(other)
    for i=1, 16 do
        self[i] = self[i] + other[i]
    end

    return self
end

function Matrix:subtract(other)
    for i=1, 16 do
        self[i] = self[i] - other[i]
    end

    return self
end

function Matrix:multiply(other)
    if type(other) == "number" then
        for i=1, 16 do
            self[i] = self[i] * other
        end
    else
        self.m11 = (((self.m11 * other.m11) + (self.m12 * other.m21)) + (self.m13 * other.m31)) + (self.m14 * other.m41)
        self.m12 = (((self.m11 * other.m12) + (self.m12 * other.m22)) + (self.m13 * other.m32)) + (self.m14 * other.m42)
        self.m13 = (((self.m11 * other.m13) + (self.m12 * other.m23)) + (self.m13 * other.m33)) + (self.m14 * other.m43)
        self.m14 = (((self.m11 * other.m14) + (self.m12 * other.m24)) + (self.m13 * other.m34)) + (self.m14 * other.m44)
        self.m21 = (((self.m21 * other.m11) + (self.m22 * other.m21)) + (self.m23 * other.m31)) + (self.m24 * other.m41)
        self.m22 = (((self.m21 * other.m12) + (self.m22 * other.m22)) + (self.m23 * other.m32)) + (self.m24 * other.m42)
        self.m23 = (((self.m21 * other.m13) + (self.m22 * other.m23)) + (self.m23 * other.m33)) + (self.m24 * other.m43)
        self.m24 = (((self.m21 * other.m14) + (self.m22 * other.m24)) + (self.m23 * other.m34)) + (self.m24 * other.m44)
        self.m31 = (((self.m31 * other.m11) + (self.m32 * other.m21)) + (self.m33 * other.m31)) + (self.m34 * other.m41)
        self.m32 = (((self.m31 * other.m12) + (self.m32 * other.m22)) + (self.m33 * other.m32)) + (self.m34 * other.m42)
        self.m33 = (((self.m31 * other.m13) + (self.m32 * other.m23)) + (self.m33 * other.m33)) + (self.m34 * other.m43)
        self.m34 = (((self.m31 * other.m14) + (self.m32 * other.m24)) + (self.m33 * other.m34)) + (self.m34 * other.m44)
        self.m41 = (((self.m41 * other.m11) + (self.m42 * other.m21)) + (self.m43 * other.m31)) + (self.m44 * other.m41)
        self.m42 = (((self.m41 * other.m12) + (self.m42 * other.m22)) + (self.m43 * other.m32)) + (self.m44 * other.m42)
        self.m43 = (((self.m41 * other.m13) + (self.m42 * other.m23)) + (self.m43 * other.m33)) + (self.m44 * other.m43)
        self.m44 = (((self.m41 * other.m14) + (self.m42 * other.m24)) + (self.m43 * other.m34)) + (self.m44 * other.m44)
    end

    return self
end

function Matrix:divide(other)
    if type(other) == "number"then
        self:multiply(1 / other)
    else
        for i=1, 16 do
            self[i] = self[i] / other[i]
        end
    end

    return self
end

function Matrix:negate()
    for i=1, 16 do
        self[i] = -self[i]
    end

    return self
end

function Matrix:decompose()
    local translation = self.translation

    local xs = (Lume.sign(self.m11 * self.m12 * self.m13 * self.m14) < 0) and -1 or 1
    local ys = (Lume.sign(self.m21 * self.m22 * self.m23 * self.m24) < 0) and -1 or 1
    local zs = (Lume.sign(self.m31 * self.m32 * self.m33 * self.m34) < 0) and -1 or 1

    local scale = Vector3(
        xs * math.sqrt(self.m11 * self.m11 + self.m12 * self.m12 + self.m13 * self.m13),
        ys * math.sqrt(self.m21 * self.m21 + self.m22 * self.m22 + self.m23 * self.m23),
        zs * math.sqrt(self.m31 * self.m31 + self.m32 * self.m32 + self.m33 * self.m33)
    )

    if (scale.x == 0.0 or scale.y == 0.0 or scale.z == 0.0) then
        return false
    end

    local m1 = Matrix(self.m11 / scale.x, self.m12 / scale.x, self.m13 / scale.x, 0,
                      self.m21 / scale.y, self.m22 / scale.y, self.m23 / scale.y, 0,
                      self.m31 / scale.z, self.m32 / scale.z, self.m33 / scale.z, 0,
                      0, 0, 0, 1
    )

    local rotation = Quaternion.createFromRotationMatrix(m1);

    return true, translation, scale, rotation;
end

function Matrix:clone()
    return Matrix(self:split())
end

function Matrix:split()
	return self.m11, self.m12, self.m13, self.m14,
           self.m21, self.m22, self.m23, self.m24,
           self.m31, self.m32, self.m33, self.m34,
           self.m41, self.m42, self.m43, self.m44
end

----------------------------
----- Static functions -----
----------------------------

function Matrix.identity()
    return Matrix(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
end

function Matrix.createWorld(position, forward, up)
    local right = Vector3.cross(forward, up)
    local up = Vector3.cross(right, forward)

    return Matrix(
        right.x,
        right.y,
        right.z,
        0,
        up.x,
        up.y,
        up.z,
        0,
        forward.x,
        forward.y,
        forward.z,
        0,
        position.x,
        position.y,
        position.z,
        1
    )
end

function Matrix.createFromAxisAngle(axis, angle)
	local quat = Quaternion.createFromAxisAngle(axis, angle)
    return Matrix.createFromQuaternion(quat)
end

function Matrix.createFromYawPitchRoll(yaw, pitch, roll)
    local quat = Quaternion.createFromYawPitchRoll(yaw, pitch, roll)
    return Matrix.createFromQuaternion(quat)
end

function Matrix.createFromQuaternion(quat)
    local squareX = quat.x * quat.x;
	local squareY = quat.y * quat.y;
	local squareZ = quat.z * quat.z;
	local num6 = quat.x * quat.y;
	local num5 = quat.z * quat.w;
	local num4 = quat.z * quat.x;
	local num3 = quat.y * quat.w;
	local num2 = quat.y * quat.z;
	local num = quat.x * quat.w;

    return Matrix(
        1 - (2 * (squareY + squareZ)),
        2 * (num6 + num5),
	    2 * (num4 - num3),
	    0,
	    2 * (num6 - num5),
	    1 - (2 * (squareZ + squareX)),
	    2 * (num2 + num),
	    0,
	    2 * (num4 + num3),
	    2 * (num2 - num),
	    1 - (2 * (squareY + squareX)),
	    0,
	    0,
	    0,
	    0,
	    1
    )
end

function Matrix.createLookAt(position, target, up)
    local forward = (position - target):normalize()
    local right = Vector3.cross(up, forward)
    local up = Vector3.cross(forward, right)

    return Matrix(
        right.x,
        up.x,
        forward.x,
        0,
        right.y,
        up.y,
        forward.y,
        0,
        right.z,
        up.z,
        forward.z,
        0,
        -Vector3.dot(right, position),
        -Vector3.dot(up, position),
        -Vector3.dot(forward, position),
        1
    )
end

function Matrix.createBillboard(objectPosition, cameraPosition, cameraUp, cameraForward)
    local forward = (objectPosition - cameraPosition):normalize()

    if forward:isNan() then
        forward = cameraForward
    end

    local right = Vector3.cross(cameraUp, forward)
    local up = Vector3.cross(forward, right)

    return Matrix(
        right.x,
        right.y,
        right.z,
        0,
        up.x,
        up.y,
        up.z,
        0,
        forward.x,
        forward.y,
        forward.z,
        0,
        objectPosition.x,
        objectPosition.y,
        objectPosition.z,
        1
    )
end

function Matrix.createConstrainedBillboard(objectPosition, cameraPosition, rotateAxis, cameraForward, objectForward)
	local forward, right
	local direction = (objectPosition - cameraPosition):normalize()

    if direction:isNan() then
        direction = cameraForward
    end

	local dot = Vector3.dot(rotateAxis, direction)
    local threshold = 0.9982547

	if (math.abs(dot) > threshold) then
	    forward = objectForward
	    dot = Vector3.dot(rotateAxis, forward, dot)

        if (math.abs(dot) > threshold) then
	        dot = Vector3.dot(rotateAxis, Vector3.forward)
	        forward = (math.abs(dot) > threshold) and Vector3.right or Vector3.forward
        end

	    right = Vector3.cross(rotateAxis, forward)
	    forward = Vector3.cross(right, rotateAxis)
	else
	    right = Vector3.cross(rotateAxis, direction)
	    forward = Vector3.cross(right, rotateAxis)
    end

    return Matrix(
        right.x,
        right.y,
        right.z,
        0,
        rotateAxis.x,
        rotateAxis.y,
        rotateAxis.z,
        0,
        forward.x,
        forward.y,
        forward.z,
        0,
        objectPosition.x,
        objectPosition.y,
        objectPosition.z,
        1
    )
end

function Matrix.createOrtographic(width, height, near, far)
    local mat = Matrix.identity()

    mat.m11 = 2 / width
    mat.m22 = 2 / height
    mat.m33 = 1 / (near - far)
    mat.m43 = near / (near - far)

    return mat
end

function Matrix.createOrthographicOffCenter(left, right, bottom, top, near, far)
    local mat = Matrix.identity()

    mat.m11 = 2 / (right - left)
    mat.m22 = 2 / (top - bottom)
    mat.m33 = 1 / (near - far)
    mat.m41 = (left + right) / (left - right)
    mat.m42 = (top + bottom) / (bottom - top)
    mat.m43 = near / (near - far)

    return mat
end

function Matrix.createPerspective(width, height, near, far)
    local negFarRange = far == math.huge and -1 or far / (near - far)
    local mat = Matrix()

    mat.m11 = (2 * near) / width
    mat.m22 = (2 * near) / height
    mat.m33 = negFarRange
    mat.m34 = -1
    mat.m43 = near * negFarRange

    return mat
end

function Matrix.createPerspectiveOffCenter(left, right, bottom, top, near, far)
    local mat = Matrix()

    mat.m11 = (2 * near) / (right - left);
	mat.m22 = (2 * near) / (top - bottom);
	mat.m31 = (left + right) / (right - left);
	mat.m32 = (top + bottom) / (top - bottom);
	mat.m33 = far / (near - far);
	mat.m34 = -1;
	mat.m43 = (near * far) / (near - far);

    return mat
end

function Matrix.createPerspectiveFOV(fov, aspectRatio, near, far)
    local yScale = 1 / math.tan(fov * 0.5)
    local xScale = yScale / aspectRatio
    local negFarRange = far == math.huge and -1 or far / (near - far)
    local mat = Matrix.identity()

    mat.m11 = xScale
    mat.m22 = yScale
    mat.m33 = negFarRange
    mat.m34 = -1
    mat.m43 = near * negFarRange

    return mat
end

function Matrix.createScale(scale)
    local mat = Matrix()

    mat.m11 = scale.width
    mat.m22 = scale.height
    mat.m33 = scale.depth

    return mat
end

function Matrix.createTranslation(position)
    local mat = Matrix.identity()

    mat.m41 = position.x
    mat.m42 = position.y
    mat.m43 = position.z

    return mat
end

return Matrix