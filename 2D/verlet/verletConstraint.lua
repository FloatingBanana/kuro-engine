local Object = require "engine.3rdparty.classic.classic"


---@class VerletConstraint: Object
---
---@field body1 VerletBody
---@field body2 VerletBody
---@field distance number
---
---@overload fun(): VerletConstraint
local VerletConstraint = Object:extend("VerletConstraint")

function VerletConstraint:new(b1, b2, dist)
    self.body1 = b1
    self.body2 = b2
    self.distance = dist or (b1.position - b2.position).length
end

function VerletConstraint:update(dt)
    local diff = self.body1.position - self.body2.position
    local diffLen = diff.length
    local diffFactor = (self.distance - diffLen) / diffLen
    local offset = diff * diffFactor*0.5

    self.body1.position:add(offset)
    self.body2.position:subtract(offset)
end

return VerletConstraint