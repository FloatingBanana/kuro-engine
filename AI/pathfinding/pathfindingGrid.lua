local Vector2 = require "engine.math.vector2"
local Lume    = require "engine.3rdparty.lume"
local Object  = require "engine.3rdparty.classic.classic"
local Grid    = Object:extend("Grid")

local function getCoord(i, size)
    return
        ((i-1) % size.width),
        math.floor((i-1) / size.width)
end

local function getIndex(x, y, size)
    return (x+1) + y * size.width
end

function Grid:new(size, callback)
    self.size = size
    self.map = {}
    self.cost = {}

    for i=1, size.width * size.height do
        local x, y = getCoord(i, size)
        local type, cost = callback(x, y)

        self.map[i] = type
        self.cost[i] = cost
    end
end

function Grid:getCell(pos)
    if pos >= self.size or pos < Vector2(0) then
        return nil, 0
    end

    local i = getIndex(pos.x, pos.y, self.size)
    return self.map[i], self.cost[i]
end


local sides = {Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)}
function Grid:getNeighbors(pos)
    local neighbors = {}

    for i=1, 4 do
        local ngPos = pos + sides[i]
        local ngType, ngcost = self:getCell(ngPos)

        if ngType and ngType ~= "wall" then
            Lume.push(neighbors, ngPos)
        end
    end

    return neighbors
end

return Grid