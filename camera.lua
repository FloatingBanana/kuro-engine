local Camera = Object:extend()

local Easing = require "engine.easing"
local Rect = require "engine.rect"
local Vector2 = require "engine.vector2"

function Camera:new(position, zoom)
    self.position = position
    self.actualPosition = position
    self.zoom = zoom

    self.easing = Easing.linear
    self.speed = 100
end

function Camera:getBounds()
    local size = Vector2(WIDTH, HEIGHT) * (1 / self.zoom)
    local topleft = self.position - (size / 2)

    return Rect(topleft, size)
end

function Camera:setInterpolation(easing, speed)
    self.easing = easing
    self.speed = speed
end

function Camera:update(dt)
    self.actualPosition = self.easing(self.actualPosition, self.position, self.speed * dt)
end

function Camera:attach()
    lg.push()

    lg.translate(WIDTH / 2, HEIGHT / 2)
    lg.scale(self.zoom)

    lg.translate(-self.actualPosition.x, -self.actualPosition.y)
end

function Camera:detach()
    lg.pop()
end

return Camera