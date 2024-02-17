local bit           = require "bit"
local PriorityQueue = require "engine.collections.priorityQueue"
local Lume          = require "engine.3rdparty.lume"
local Object        = require "engine.3rdparty.classic.classic"
local Finder        = Object:extend("Finder")

local function hash(vec)
    return bit.bxor(vec.x * 397, vec.y)
end

local function manhattan(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

local function euclidean(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function Finder:new()
end

function Finder:findPath(grid, from, to)
    local frontier = PriorityQueue()
    local fromHash = hash(from)
    local toHash = hash(to)
    self.searched = {}

    local came_from = {[fromHash] = from}
    local total_cost = {[fromHash] = 0}

    frontier:push(0, from)

    while frontier:getLength() > 0 do
        local _, currPos = frontier:pop() --- @cast currPos Vector2
        local currHash = hash(currPos)

        if currPos == to then
            break
        end

        for i, nextPos in ipairs(grid:getNeighbors(currPos)) do --- @cast nextPos Vector2
            local nextType, nextCost = grid:getCell(nextPos)
            local newCost = total_cost[currHash] + nextCost
            local nextHash = hash(nextPos)

            if not total_cost[nextHash] or newCost < total_cost[nextHash] then
                total_cost[nextHash] = newCost
                came_from[nextHash] = currPos

                frontier:push(-newCost - manhattan(to, nextPos), nextPos)

                Lume.push(self.searched, nextPos)
            end
        end
    end

    if not came_from[toHash] then
        return nil
    end

    local path = {came_from[toHash], to}

    repeat
        local cell = came_from[hash(path[1])]

        table.insert(path, 1, cell)
    until cell == from

    return path
end

return Finder