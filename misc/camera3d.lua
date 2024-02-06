local Matrix  = require "engine.math.matrix"
local Vector3 = require "engine.math.vector3"
local Object  = require "engine.3rdparty.classic.classic"

--- @class Camera3D
--- 
--- @field position Vector3
--- @field rotation Quaternion
--- @field fov number
--- @field aspectRatio number
--- @field nearPlane number
--- @field farPlane number
--- @field viewMatrix Matrix
--- @field projectionMatrix Matrix
--- @field viewProjectionMatrix Matrix
--- @field invViewMatrix Matrix
--- @field invProjectionMatrix Matrix
--- @field invViewProjectionMatrix Matrix
---
--- @operator call: Camera3D
local Camera = Object:extend("Camera3D")

function Camera:new(position, rotation, fov, aspectRatio, nearPlane, farPlane)
    self.position = position
    self.rotation = rotation
    self.fov = fov
    self.aspectRatio = aspectRatio
    self.nearPlane = nearPlane
    self.farPlane = farPlane

    self.viewMatrix = nil
    self.projectionMatrix = nil
    self.viewProjectionMatrix = nil

    self.invViewMatrix = nil
    self.invProjectionMatrix = nil
    self.invViewProjectionMatrix = nil
end

function Camera:__index(key)
    if key == "viewMatrix" then
        return Matrix.CreateLookAtDirection(self.position, Vector3(0,0,1):transform(self.rotation), Vector3(0,1,0):transform(self.rotation))
    end

    if key == "projectionMatrix" then
        return Matrix.CreatePerspectiveFOV(self.fov, self.aspectRatio, self.nearPlane, self.farPlane)
    end

    if key == "viewProjectionMatrix" then
        return self.viewMatrix * self.projectionMatrix
    end

    return Camera[key]
end

function Camera:updateMatrices()
    self.viewMatrix = Matrix.CreateLookAtDirection(self.position, Vector3(0,0,1):transform(self.rotation), Vector3(0,1,0):transform(self.rotation))
    self.projectionMatrix = Matrix.CreatePerspectiveFOV(self.fov, self.aspectRatio, self.nearPlane, self.farPlane)
    self.viewProjectionMatrix = self.viewMatrix * self.projectionMatrix

    self.invViewMatrix = self.viewMatrix.inverse
    self.invProjectionMatrix = self.projectionMatrix.inverse
    self.invViewProjectionMatrix = self.viewProjectionMatrix.inverse
end

return Camera