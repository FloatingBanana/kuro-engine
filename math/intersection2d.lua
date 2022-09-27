local Vector2 = require "engine.math.vector2"
local Inter2d = {}

-----------
-- Point --
-----------
function Inter2d.point_AABB(point,   topleft,bottomright)
    return point > topleft and point < bottomright
end

function Inter2d.point_circle(point,   circlePos,circleRadius)
    return Inter2d.circle_circle(point, 0, circlePos, circleRadius)
end



---------
-- Ray --
---------
function Inter2d.ray_circle(rayPos,rayDir,   circlePos,circleRadius)
    local circleDir = circlePos - rayPos
    local proj = Vector2.dot(circleDir, rayDir) * rayDir
    local dist = Vector2.distance(circleDir, proj)

    if dist <= circleRadius then
        local m = math.sqrt(circleRadius*circleRadius - dist*dist)

        local p1 = rayPos + proj - m * rayDir
        local p2 = rayPos + proj + m * rayDir
        return true, p1, p2
    else
        return false, nil, nil
    end
end



----------
-- AABB --
----------
function Inter2d.AABB_AABB(topleft1,bottomright1,   topleft2,bottomright2)
    return topleft1 < bottomright2 and topleft2 < bottomright1
end

function Inter2d.AABB_circle(topleft,bottomright,   circlePos,circleRadius)
    local nearest = circlePos:clone():clamp(topleft, bottomright)
    return Inter2d.point_circle(nearest, circlePos, circleRadius)
end



------------
-- Circle --
------------
function Inter2d.circle_circle(pos1,radius1,   pos2,radius2)
    local totalRadius = radius1 + radius2
    local dist = Vector2.distance(pos1, pos2)

    if dist < totalRadius then
        return true, totalRadius - dist
    end
    return false
end

return Inter2d