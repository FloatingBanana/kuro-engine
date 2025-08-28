local Matrix4 = require "engine.math.matrix4"
local Vector3 = require "engine.math.vector3"
local Object  = require "engine.3rdparty.classic.classic"

---@alias ProjectionType "perspective" | "orthographic"

--- @class Camera3D: Object
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
--- @field projectionMatrix Matrix4
--- @field viewProjectionMatrix Matrix4
--- @field forward Vector3
--- @field backward Vector3
--- @field up Vector3
--- @field down Vector3
--- @field left Vector3
--- @field right Vector3
--- @field type ProjectionType
---
--- @overload fun(position: Vector3, rotation: Quaternion, fov: number, screenSize: Vector2, nearPlane: number, farPlane: number, type: ProjectionType?): Camera3D
local Camera = Object:extend("Camera3D")

function Camera:new(position, rotation, fov, screenSize, nearPlane, farPlane, type)
    self.position = position
    self.rotation = rotation
    self.fov = fov
    self.screenSize = screenSize
    self.nearPlane = nearPlane
    self.farPlane = farPlane
    self.type = type or "perspective"
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

    if key == "projectionMatrix" then
        if self.type == "perspective" then
            return self.perspectiveMatrix
        elseif self.type == "orthographic" then
            return self.orthographicMatrix
        else
            error("Unknown camera projection type: " .. tostring(self.type))
        end
    end

    if key == "viewProjectionMatrix" then
        return self.viewMatrix:multiply(self.projectionMatrix)
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