local Matrix4 = require "engine.math.matrix4"
local Vector3 = require "engine.math.vector3"
local Object  = require "engine.3rdparty.classic.classic"

--- @class Camera3D
--- 
--- @field position Vector3
--- @field rotation Quaternion
--- @field fov number
--- @field screenSize Vector2
--- @field nearPlane number
--- @field farPlane number
--- @field viewMatrix Matrix4
--- @field perspectiveMatrix Matrix4
--- @field orthographicMatrix Matrix4
--- @field viewPerspectiveMatrix Matrix4
--- @field viewOrthographicMatrix Matrix4
--- @field forward Vector3
--- @field backward Vector3
--- @field up Vector3
--- @field down Vector3
--- @field left Vector3
--- @field right Vector3
---
--- @overload fun(position: Vector3, rotation: Quaternion, fov: number, screenSize: Vector2, nearPlane: number, farPlane: number): Camera3D
local Camera = Object:extend("Camera3D")

function Camera:new(position, rotation, fov, screenSize, nearPlane, farPlane)
    self.position = position
    self.rotation = rotation
    self.fov = fov
    self.screenSize = screenSize
    self.nearPlane = nearPlane
    self.farPlane = farPlane
end

function Camera:__index(key)
    if key == "viewMatrix" then
        return Matrix4.CreateLookAtDirection(self.position, self.forward, self.up)
    end

    if key == "perspectiveMatrix" then
        return Matrix4.CreatePerspectiveFOV(self.fov, self.screenSize.width / self.screenSize.height, self.nearPlane, self.farPlane)
    end

    if key == "orthographicMatrix" then
        return Matrix4.CreateOrthographic(self.screenSize.width, self.screenSize.height, self.nearPlane, self.farPlane)
    end

    if key == "viewPerspectiveMatrix" then
        return self.viewMatrix * self.perspectiveMatrix
    end

    if key == "viewOrthographicMatrix" then
        return self.viewMatrix * self.perspectiveMatrix
    end

    if key == "forward" then
        return Vector3(0,0,1):transform(self.rotation)
    end

    if key == "backward" then
        return Vector3(0,0,-1):transform(self.rotation)
    end

    if key == "up" then
        return Vector3(0,1,0):transform(self.rotation)
    end

    if key == "down" then
        return Vector3(0,-1,0):transform(self.rotation)
    end

    if key == "right" then
        return Vector3(1,0,0):transform(self.rotation)
    end

    if key == "left" then
        return Vector3(-1,0,0):transform(self.rotation)
    end

    return Camera[key]
end

return Camera