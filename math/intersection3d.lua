local Vector3 = require "engine.math.vector3"
local Inter3d = {}

-----------
-- Point --
-----------
function Inter3d.point_AABB(point,   topleft,bottomright)
    return Inter3d.AABB_AABB(topleft, bottomright, point, point)
end

function Inter3d.point_sphere(point,   circlePos,circleRadius)
    return Inter3d.sphere_sphere(point, 0, circlePos, circleRadius)
end



---------
-- Ray --
---------
function Inter3d.ray_sphere(rayPos,rayDir,   circlePos,circleRadius)
    local circleDir = circlePos - rayPos
    local proj = Vector3.Dot(circleDir, rayDir) * rayDir
    local dist = Vector3.Distance(circleDir, proj)

    if dist <= circleRadius then
        local m = math.sqrt(circleRadius*circleRadius - dist*dist)

        local p1 = rayPos + proj - m * rayDir
        local p2 = rayPos + proj + m * rayDir
        return true, p1, p2
    else
        return false, Vector3(0), Vector3(0)
    end
end


function Inter3d.ray_plane(rayPos,rayDir,   planePos,planeNormal)
    local denom = Vector3.Dot(planeNormal, rayDir)

    if math.abs(denom) > 1e-6 then
        local t = Vector3.Dot(planePos - rayPos, planeNormal) / denom
        return t >= 0, rayPos + t * rayDir
    end

    return false, 0
end


function Inter3d.ray_AABB(rayPos, rayDir,   topleft,bottomright)
    local tmin = (topleft - rayPos) / rayDir
    local tmax = (bottomright - rayPos) / rayDir

    if tmin.x > tmax.x then tmin.x, tmax.x = tmax.x, tmin.x end
    if tmin.y > tmax.y then tmin.y, tmax.y = tmax.y, tmin.y end
    if tmin.z > tmax.z then tmin.z, tmax.z = tmax.z, tmin.z end

    local tNear = math.max(tmin.x, math.max(tmin.y, tmin.z))
    local tFar  = math.min(tmax.x, math.min(tmax.y, tmax.z))

    return tNear <= tFar and tFar >= 0, tNear, tFar
end



----------
-- AABB --
----------
function Inter3d.AABB_AABB(topleft1,bottomright1,   topleft2,bottomright2)
    return
        topleft1.x < bottomright2.x and topleft2.x < bottomright1.x and
        topleft1.y < bottomright2.y and topleft2.x < bottomright1.x and
        topleft1.z < bottomright2.z and topleft2.z < bottomright1.z
end

function Inter3d.AABB_sphere(topleft,bottomright,   circlePos,circleRadius)
    local nearest = circlePos:clone():clamp(topleft, bottomright)
    return Inter3d.point_sphere(nearest, circlePos, circleRadius)
end



------------
-- Sphere --
------------
function Inter3d.sphere_sphere(pos1,radius1,   pos2,radius2)
    local totalRadius = radius1 + radius2
    local dist = Vector3.Distance(pos1, pos2)

    if dist < totalRadius then
        return true, totalRadius - dist
    end
    return false
end

return Inter3d