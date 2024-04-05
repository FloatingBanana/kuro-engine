local Object = require "engine.3rdparty.classic.classic"
local Vector2 = require "engine.math.vector2"

-- https://pikuma.com/blog/verlet-integration-2d-cloth-physics-simulation
---@class VerletBody: Object
---
---@field position Vector2
---@field prevPosition Vector2
---@field mass number
---
---@overload fun(pos: Vector2, mass: number): VerletBody
local VerletBody = Object:extend("VerletBody")

function VerletBody:new(pos, mass)
    self.position = pos
    self.prevPosition = pos
    self.mass = mass
    self.force = Vector2()
end

function VerletBody:update(dt)
    local acc = self.force / self.mass
    local prevPos = self.position

    self.position = 2 * self.position - self.prevPosition + acc * dt*dt
    self.prevPosition = prevPos
end

return VerletBody