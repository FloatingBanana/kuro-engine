local Object = require "engine.3rdparty.classic.classic"
local Vector4 = require "engine.math.vector4"


---@class CameraFrustum: Object
---
---@field public topPlane Vector4
---@field public bottomPlane Vector4
---@field public leftPlane Vector4
---@field public rightPlane Vector4
---@field public nearPlane Vector4
---@field public farPlane Vector4
---
---@overload fun(): CameraFrustum
local CameraFrustum = Object:extend("CameraFrustum")

function CameraFrustum:new()
    self.topPlane    = Vector4()
    self.bottomPlane = Vector4()
    self.leftPlane   = Vector4()
    self.rightPlane  = Vector4()
    self.nearPlane   = Vector4()
    self.farPlane    = Vector4()
end


---@param viewProj Matrix
---@return self
function CameraFrustum:updatePlanes(viewProj)
    self.nearPlane   = Vector4( viewProj.m13 + viewProj.m14, viewProj.m23 + viewProj.m24, viewProj.m33 + viewProj.m34, viewProj.m43 + viewProj.m44):normalize()
    self.farPlane    = Vector4(-viewProj.m13 + viewProj.m14,-viewProj.m23 + viewProj.m24,-viewProj.m33 + viewProj.m34,-viewProj.m43 + viewProj.m44):normalize()
    self.bottomPlane = Vector4( viewProj.m12 + viewProj.m14, viewProj.m22 + viewProj.m24, viewProj.m32 + viewProj.m34, viewProj.m42 + viewProj.m44):normalize()
    self.topPlane    = Vector4(-viewProj.m12 + viewProj.m14,-viewProj.m22 + viewProj.m24,-viewProj.m32 + viewProj.m34,-viewProj.m42 + viewProj.m44):normalize()
    self.leftPlane   = Vector4( viewProj.m11 + viewProj.m14, viewProj.m21 + viewProj.m24, viewProj.m31 + viewProj.m34, viewProj.m41 + viewProj.m44):normalize()
    self.rightPlane  = Vector4(-viewProj.m11 + viewProj.m14,-viewProj.m21 + viewProj.m24,-viewProj.m31 + viewProj.m34,-viewProj.m41 + viewProj.m44):normalize()

    return self
end


---@param bounding BoundingBox
---@param worldMatrix Matrix?
---@return boolean
function CameraFrustum:testIntersection(bounding, worldMatrix)
    local min, max = bounding.min, bounding.max

    if worldMatrix then
        min, max = bounding:getMinMaxTransformed(worldMatrix)
    end

    for i=1, 6 do
        local plane = select(i, self.topPlane, self.bottomPlane, self.leftPlane, self.rightPlane, self.farPlane, self.nearPlane)
        local pos = Vector4(0,0,0,1)
        pos.x = (plane.x < 0) and min.x or max.x
        pos.y = (plane.y < 0) and min.y or max.y
        pos.z = (plane.z < 0) and min.z or max.z

        if Vector4.Dot(plane, pos) < 0 then
            return false
        end
    end
    return true
end

return CameraFrustum