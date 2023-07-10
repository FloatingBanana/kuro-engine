local Matrix = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local Camera = Object:extend()

function Camera:new(position, direction, fov, aspectRatio, nearPlane, farPlane)
    self.position = position
    self.direction = direction
    self.fov = fov
    self.aspectRatio = aspectRatio
    self.nearPlane = nearPlane
    self.farPlane = farPlane
end

function Camera:__index(key)
    if key == "viewMatrix" then
        return Matrix.CreateLookAtDirection(self.position, self.direction, Vector3(0,1,0))
    end

    if key == "projectionMatrix" then
        return Matrix.CreatePerspectiveFOV(self.fov, self.aspectRatio, self.nearPlane, self.farPlane)
    end

    if key == "viewProjectionMatrix" then
        return self.viewMatrix * self.projectionMatrix
    end

    return Camera[key]
end

return Camera