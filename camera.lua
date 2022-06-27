local Camera = Object:extend()

local Rect = require "engine.rect"

function Camera:new(position, zoom)
    self.position = position

    self.zoom = zoom
end

function Camera:getBounds()
    local size = Vector(WIDTH, HEIGHT) * (1 / self.zoom)
    local topleft = self.position - (size / 2)

    return Rect(topleft, size)
end

function Camera:attach()
    lg.push()
    lg.translate(WIDTH / 2, HEIGHT / 2)
    lg.scale(self.zoom)
    lg.translate(-self.position.x, -self.position.y)
end

function Camera:detach()
    lg.pop()
end

return Camera