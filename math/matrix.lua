local Vector3 = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local CStruct = require "engine.cstruct"

-- See [engine/vector2.lua] for explanation
local function commutative_reorder(object, number)
    if type(object) == "number" then
        return number, object
    end
    return object, number
end


---
--- A right-handed 4x4 matrix. Mostly used to store 3D transformations.
---
--- @class Matrix: CStruct
---
--- @field translation Vector3: The translation part of this matrix (m41, m42, m43)
--- @field forward Vector3: The forward direction of this matrix (m31, m32, m33)
--- @field up Vector3: The up direction of this matrix (m21, m22, m23)
--- @field right Vector3: The right direction of this matrix (m11, m12, m13)
--- @field backward Vector3: The backward direction of this matrix (-m31, -m32, -m33)
--- @field down Vector3: The down direction of this matrix (-m21, -m22, -m23)
--- @field left Vector3: The left direction of this matrix (-m11, -m12, -m13)
---
--- @field scale Vector3: Gets the scaling factor of this matrix
--- @field rotation Quaternion: Gets the rotation factor of this matrix
--- @field transposed Matrix: Gets a copy of this matrix with the components transposed
--- @field inverse Matrix: Gets a copy of this matrix with the components inverted
--- @field m11 number
--- @field m12 number
--- @field m13 number
--- @field m14 number
--- @field m21 number
--- @field m22 number
--- @field m23 number
--- @field m24 number
--- @field m31 number
--- @field m32 number
--- @field m33 number
--- @field m34 number
--- @field m41 number
--- @field m42 number
--- @field m43 number
--- @field m44 number
---
--- @operator call: Matrix
--- @operator add: Matrix
--- @operator sub: Matrix
--- @operator mul: Matrix
--- @operator div: Matrix
--- @operator unm: Matrix
--- @operator len: number
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
    if key == "forward"     then return Vector3(self.m31, self.m32, self.m33) end
    if key == "up"          then return Vector3(self.m21, self.m22, self.m23) end
    if key == "right"       then return Vector3(self.m11, self.m12, self.m23) end

    -- Opposite vectors
    if key == "backward" then return self.forward:negate() end
    if key == "down"     then return self.up:negate()      end
    if key == "left"     then return self.right:negate()   end

    if key == "scale" then
        local xs = (self.m11 * self.m12 * self.m13 * self.m14 < 0) and -1 or 1
        local ys = (self.m21 * self.m22 * self.m23 * self.m24 < 0) and -1 or 1
        local zs = (self.m31 * self.m32 * self.m33 * self.m34 < 0) and -1 or 1

        return Vector3(
            xs * math.sqrt(self.m11 * self.m11 + self.m12 * self.m12 + self.m13 * self.m13),
            ys * math.sqrt(self.m21 * self.m21 + self.m22 * self.m22 + self.m23 * self.m23),
            zs * math.sqrt(self.m31 * self.m31 + self.m32 * self.m32 + self.m33 * self.m33)
        )
    end

    if key == "rotation" then
        local scale = self.scale

        local m1 = Matrix(self.m11 / scale.x, self.m12 / scale.x, self.m13 / scale.x, 0,
                          self.m21 / scale.y, self.m22 / scale.y, self.m23 / scale.y, 0,
                          self.m31 / scale.z, self.m32 / scale.z, self.m33 / scale.z, 0,
                          0, 0, 0, 1
        )

        return Quaternion.createFromRotationMatrix(m1);
    end

    if key == "transposed" then
        return self:clone():transpose()
    end

    if key == "inverse" then
        return self:clone():invert()
    end

    return Matrix[key]
end

function Matrix:__newindex(key, value)
    if numberIndexes[key] then
        self[numberIndexes[key]] = value
        return
    end

    if key == "translation" then --- @cast value Vector3
        self.m41, self.m42, self.m43 = value:split()
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

function Matrix:__mul(value)
    self, value = commutative_reorder(self, value)
    return self:clone():multiply(value)
end

function Matrix:__div(value)
    self, value = commutative_reorder(self, value)
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

function Matrix:__tostring()
    return ("Matrix(\n\t%03f, %03f, %03f, %03f,\n\t%03f, %03f, %03f, %03f,\n\t%03f, %03f, %03f, %03f,\n\t%03f, %03f, %03f, %03f\n)"):format(self:split())
end

---------------------
------ Methods ------
---------------------


--- Peforms an addition operation on this matrix (`self + other`)
--- @param other Matrix | number: The right hand operand
--- @return Matrix: This matrix
function Matrix:add(other)
    for i=1, 16 do
        self[i] = self[i] + other[i]
    end

    return self
end


--- Peforms a subtraction operation on this matrix (`self - other`)
--- @param other Matrix | number: The right hand operand
--- @return Matrix: This matrix
function Matrix:subtract(other)
    for i=1, 16 do
        self[i] = self[i] - other[i]
    end

    return self
end


--- Peforms a multiplication operation on this matrix (`self * other`)
--- @param other Matrix | number: The right hand operand
--- @return Matrix: This matrix
function Matrix:multiply(other)
    if type(other) == "number" then
        for i=1, 16 do
            self[i] = self[i] * other
        end
    else
        self:new(
            (((self.m11 * other.m11) + (self.m12 * other.m21)) + (self.m13 * other.m31)) + (self.m14 * other.m41),
            (((self.m11 * other.m12) + (self.m12 * other.m22)) + (self.m13 * other.m32)) + (self.m14 * other.m42),
            (((self.m11 * other.m13) + (self.m12 * other.m23)) + (self.m13 * other.m33)) + (self.m14 * other.m43),
            (((self.m11 * other.m14) + (self.m12 * other.m24)) + (self.m13 * other.m34)) + (self.m14 * other.m44),
            (((self.m21 * other.m11) + (self.m22 * other.m21)) + (self.m23 * other.m31)) + (self.m24 * other.m41),
            (((self.m21 * other.m12) + (self.m22 * other.m22)) + (self.m23 * other.m32)) + (self.m24 * other.m42),
            (((self.m21 * other.m13) + (self.m22 * other.m23)) + (self.m23 * other.m33)) + (self.m24 * other.m43),
            (((self.m21 * other.m14) + (self.m22 * other.m24)) + (self.m23 * other.m34)) + (self.m24 * other.m44),
            (((self.m31 * other.m11) + (self.m32 * other.m21)) + (self.m33 * other.m31)) + (self.m34 * other.m41),
            (((self.m31 * other.m12) + (self.m32 * other.m22)) + (self.m33 * other.m32)) + (self.m34 * other.m42),
            (((self.m31 * other.m13) + (self.m32 * other.m23)) + (self.m33 * other.m33)) + (self.m34 * other.m43),
            (((self.m31 * other.m14) + (self.m32 * other.m24)) + (self.m33 * other.m34)) + (self.m34 * other.m44),
            (((self.m41 * other.m11) + (self.m42 * other.m21)) + (self.m43 * other.m31)) + (self.m44 * other.m41),
            (((self.m41 * other.m12) + (self.m42 * other.m22)) + (self.m43 * other.m32)) + (self.m44 * other.m42),
            (((self.m41 * other.m13) + (self.m42 * other.m23)) + (self.m43 * other.m33)) + (self.m44 * other.m43),
            (((self.m41 * other.m14) + (self.m42 * other.m24)) + (self.m43 * other.m34)) + (self.m44 * other.m44)
        )
    end

    return self
end


--- Peforms a division operation on this matrix (`self / other`)
--- @param other Matrix | number: The right hand operand
--- @return Matrix: This matrix
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


--- Negates all components of this matrix
--- @return Matrix: This matrix
function Matrix:negate()
    for i=1, 16 do
        self[i] = -self[i]
    end

    return self
end


--- Swap the rows and colums of this matrix
--- @return Matrix: This matrix
function Matrix:transpose()
    -- Calling the raw constructor just assigns the arguments to the matrix
    self:new(
        self.m11,
        self.m21,
        self.m31,
        self.m41,

        self.m12,
        self.m22,
        self.m32,
        self.m42,

        self.m13,
        self.m23,
        self.m33,
        self.m43,

        self.m14,
        self.m24,
        self.m34,
        self.m44
    )

    return self
end


--- Invert all components of this matrix
--- @return Matrix: This matrix
function Matrix:invert()
    -- Determinants
    local det1 = self.m11 * self.m22 - self.m12 * self.m21;
    local det2 = self.m11 * self.m23 - self.m13 * self.m21;
    local det3 = self.m11 * self.m24 - self.m14 * self.m21;
    local det4 = self.m12 * self.m23 - self.m13 * self.m22;
    local det5 = self.m12 * self.m24 - self.m14 * self.m22;
    local det6 = self.m13 * self.m24 - self.m14 * self.m23;
    local det7 = self.m31 * self.m42 - self.m32 * self.m41;
    local det8 = self.m31 * self.m43 - self.m33 * self.m41;
    local det9 = self.m31 * self.m44 - self.m34 * self.m41;
    local det10 = self.m32 * self.m43 - self.m33 * self.m42;
    local det11 = self.m32 * self.m44 - self.m34 * self.m42;
    local det12 = self.m33 * self.m44 - self.m34 * self.m43;
    local major = (det1*det12 - det2*det11 + det3*det10 + det4*det9 - det5*det8 + det6*det7);
    local invMajor = 1 / major

    self:new(
        (self.m22*det12 - self.m23*det11 + self.m24*det10) * invMajor,
        (-self.m12*det12 + self.m13*det11 - self.m14*det10) * invMajor,
        (self.m42*det6 - self.m43*det5 + self.m44*det4) * invMajor,
        (-self.m32*det6 + self.m33*det5 - self.m34*det4) * invMajor,
        (-self.m21*det12 + self.m23*det9 - self.m24*det8) * invMajor,
        (self.m11*det12 - self.m13*det9 + self.m14*det8) * invMajor,
        (-self.m41*det6 + self.m43*det3 - self.m44*det2) * invMajor,
        (self.m31*det6 - self.m33*det3 + self.m34*det2) * invMajor,
        (self.m21*det11 - self.m22*det9 + self.m24*det7) * invMajor,
        (-self.m11*det11 + self.m12*det9 - self.m14*det7) * invMajor,
        (self.m41*det5 - self.m42*det3 + self.m44*det1) * invMajor,
        (-self.m31*det5 + self.m32*det3 - self.m34*det1) * invMajor,
        (-self.m21*det10 + self.m22*det8 - self.m23*det7) * invMajor,
        (self.m11*det10 - self.m12*det8 + self.m13*det7) * invMajor,
        (-self.m41*det4 + self.m42*det2 - self.m43*det1) * invMajor,
        (self.m31*det4 - self.m32*det2 + self.m33*det1) * invMajor
    )

    return self
end


--- Internaly converts this matrix to a 3x3 matrix
---
--- Only use this method if you want to send this matrix to a shader as a `mat3` uniform
--- @return Matrix: This matrix
function Matrix:to3x3()
    self:new(
        self.m11, self.m12, self.m13,
        self.m21, self.m22, self.m23,
        self.m31, self.m32, self.m33,
        0,0,0,0,0,0,0
    )

    return self
end


--- Checks if the translation, scale and rotation can be extracted from this matrix
--- @return boolean: `true` if this matrix can be decomposed, `false` otherwise
function Matrix:isDecomposable()
    local scale = self.scale
    return scale.x ~= 0 and scale.y ~= 0 and scale.z ~= 0
end


--- Extracts the translation, scale and rotation of this matrix
--- @return Vector3 Translation, Vector3 Scale, Quaternion Rotation
function Matrix:decompose()
    return self.translation, self.scale, self.rotation;
end


--- Creates a new matrix with the same component values of this one
--- @return Matrix: The new matrix
function Matrix:clone()
    return Matrix(self:split())
end


--- Deconstruct this matrix into individual values
--- @return number m11, number m12, number m13, number m14, number m21, number m22, number m23, number m24, number m31, number m32, number m33, number m34, number m41, number m42, number m43, number m44
function Matrix:split()
	return self.m11, self.m12, self.m13, self.m14,
           self.m21, self.m22, self.m23, self.m24,
           self.m31, self.m32, self.m33, self.m34,
           self.m41, self.m42, self.m43, self.m44
end

----------------------------
----- Static functions -----
----------------------------


--- Creates an identity matrix
--- @return Matrix
function Matrix.identity()
    return Matrix(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
end


--- Creates a world matrix
--- @param position Vector3: The world position
--- @param forward Vector3: The forward direction
--- @param up Vector3: The up direction
--- @return Matrix: The resulting world matrix
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


--- Creates a matrix rotated by an `angle` around an `axis`
--- @param axis Vector3: The axis of rotation
--- @param angle number: The angle of rotation
--- @return Matrix: Result
function Matrix.createFromAxisAngle(axis, angle)
	local quat = Quaternion.createFromAxisAngle(axis, angle)
    return Matrix.createFromQuaternion(quat)
end


--- Creates a rotation matrix with the equivalent yaw, pitch and roll
--- @param yaw number: Yaw around the Y axis
--- @param pitch number: Pitch around the X axis
--- @param roll number: Roll around the Z axis
--- @return Matrix: Result
function Matrix.createFromYawPitchRoll(yaw, pitch, roll)
    local quat = Quaternion.createFromYawPitchRoll(yaw, pitch, roll)
    return Matrix.createFromQuaternion(quat)
end


--- Creates a rotation matrix from a Quaternion
--- @param quat Quaternion: The Quaternion representing the rotation
--- @return Matrix: Result
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


--- Creates a view matrix looking at a specified direction
--- @param position Vector3: The view position
--- @param direction Vector3: The view direction
--- @param up Vector3: A vector pointing up from view's position
--- @return Matrix: Result
function Matrix.createLookAtDirection(position, direction, up)
    local forward = -direction
    local right = Vector3.cross(up, forward):normalize()
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


--- Creates a view matrix looking at a specified target
--- @param position Vector3: The view position
--- @param target Vector3: The view target
--- @param up Vector3: A vector pointing up from view's position
--- @return Matrix: Result
function Matrix.createLookAt(position, target, up)
    return Matrix.createLookAtDirection(position, (target - position):normalize(), up)
end


--- Creates a spherical billboard matrix that rotates around a specified position
--- @param objectPosition Vector3: Billboard position
--- @param cameraPosition Vector3: The view position
--- @param cameraUp Vector3: A vector pointing up from view's position
--- @param cameraForward Vector3: A vector pointing forward from view's position
--- @return Matrix: Result
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


--- Creates a cylindrical billboard matrix that rotates around a specified axis
--- @param objectPosition Vector3: Billboard position
--- @param cameraPosition Vector3: The view position
--- @param rotateAxis Vector3: Axis of billboard rotation
--- @param cameraForward Vector3: A vector pointing forward from view's position
--- @param objectForward Vector3: A vector pointing forward from billboard's position
--- @return Matrix: Result
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
	        dot = Vector3.dot(rotateAxis, Vector3(0,0,-1))
	        forward = (math.abs(dot) > threshold) and Vector3(1,0,0) or Vector3(0,0,-1)
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


--- Creates an orthographic projection matrix
--- @param width number: Width of the view volume
--- @param height number: Height of the view volume
--- @param near number: Near plane depht
--- @param far number: Far plane depth
--- @return Matrix: Result
function Matrix.createOrtographic(width, height, near, far)
    local mat = Matrix.identity()

    mat.m11 = 2 / width
    mat.m22 = 2 / height
    mat.m33 = 1 / (near - far)
    mat.m43 = near / (near - far)

    return mat
end


--- Creates an orthographic projection matrix with a custom view volume
--- @param left number: Near plane's lower x value
--- @param right number: Near plane's upper x value
--- @param bottom number: Near plane's lower y value
--- @param top number: Near plane's upper Y value
--- @param near number: Near plane depth
--- @param far number: Far plane depht
--- @return Matrix: Result
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


--- Creates a perspective projection matrix
--- @param width number: Width of the view volume
--- @param height number: Height of the view volume
--- @param near number: Near plane distance
--- @param far number: Far plane distance
--- @return Matrix: Result
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


--- Creates a perspective projection matrix with a custom view volume
--- @param left number: Near plane's lower x value
--- @param right number: Near plane's upper x value
--- @param bottom number: Near plane's lower y value
--- @param top number: Near plane's upper Y value
--- @param near number: Near plane distance
--- @param far number: Far plane distance
--- @return Matrix: Result
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


--- Creates a perspective projection matrix with a field of view
--- @param fov number: Field of view angle
--- @param aspectRatio number: Aspect ratio (i.e `width / height`) of the view volume
--- @param near number: Near plane distance
--- @param far number: Far plane distance. `math.huge` is also acceptable
--- @return Matrix: Result
function Matrix.createPerspectiveFOV(fov, aspectRatio, near, far)
    local yScale = 1 / math.tan(fov * 0.5)
    local xScale = yScale / aspectRatio
    local negFarRange = far == math.huge and -1 or far / (near - far)
    local mat = Matrix()

    mat.m11 = xScale
    mat.m22 = yScale
    mat.m33 = negFarRange
    mat.m34 = -1
    mat.m43 = near * negFarRange

    return mat
end


--- Creates a scaling matrix
--- @param scale Vector3: The scale value on each axis
--- @return Matrix: Result
function Matrix.createScale(scale)
    local mat = Matrix.identity()

    mat.m11 = scale.width
    mat.m22 = scale.height
    mat.m33 = scale.depth

    return mat
end


--- Creates a translation matrix
--- @param position Vector3: The translation coordinates
--- @return Matrix: Result
function Matrix.createTranslation(position)
    local mat = Matrix.identity()

    mat.m41 = position.x
    mat.m42 = position.y
    mat.m43 = position.z

    return mat
end


--- Creates a matrix with rotation, scale and translation informations
--- @param rotation Quaternion: The rotation factor
--- @param scale Vector3: The scaling factor
--- @param translation Vector3: The translation coordinates
--- @return Matrix: Result
function Matrix.createTransformationMatrix(rotation, scale, translation)
    local matRot = Matrix.createFromQuaternion(rotation)
    local matScale = Matrix.createScale(scale)
    local matTranslation = Matrix.createTranslation(translation)

    return matRot:multiply(matScale):multiply(matTranslation)
end

return Matrix
