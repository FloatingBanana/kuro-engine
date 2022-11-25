local Vector2 = require "engine.math.vector2"
local Grid = Object:extend()

function Grid:new(size, callback)
    self.map = {}

    for y=0, size.height-1 do
        self.map[y] = {}

        for x=0, size.width-1 do
            local type, cost = callback(x, y)

            self.map[y][x] = {type = type, cost = cost}
        end
    end
end

function Grid:getCell(pos)
    if self.map[pos.y] then
        return self.map[pos.y][pos.x]
    end

    return nil
end


local sides = {Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)}
function Grid:getNeighbors(pos)
    local neighbors = {}

    for i=1, 4 do
        local ngPos = pos + sides[i]
        local ngValue = self:getCell(ngPos)

        if ngValue and ngValue.type ~= "wall" then
            Lume.push(neighbors, ngPos)
        end
    end

    return neighbors
end

return Grid