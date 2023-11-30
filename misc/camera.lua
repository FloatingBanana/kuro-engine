local Camera = Object:extend()

local Easing  = require "engine.math.easing"
local Rect    = require "engine.math.rect"
local Vector2 = require "engine.math.vector2"
local Timer   = require "engine.misc.timer"

function Camera:new(position, zoom)
    self.position = position
    self.actualPosition = position
    self.zoom = zoom

    self.easing = Easing.linear
    self.speed = 100

    self.shakeTimer = Timer(0, 0, false)
    self.shakeShiftTimer = Timer(0, 0, true)
    self.shakeIntensity = 0
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

function Camera:shake(time, intensity, shakeSpeed)
    self.shakeTimer.duration = time
    self.shakeShiftTimer.duration = shakeSpeed
    self.shakeIntensity = intensity

    self.shakeTimer:restart():play()
    self.shakeShiftTimer:restart():play()
end

function Camera:update(dt)
    local shakeOffset = Vector2()

    if self.shakeTimer:update(dt).running then
        if self.shakeShiftTimer:update(dt).justEnded then
            local int = 1 - (self.shakeTimer.time / self.shakeTimer.duration)

            shakeOffset.x = math.random(-int, int) * self.shakeIntensity
            shakeOffset.y = math.random(-int, int) * self.shakeIntensity
        end
    end

    self.actualPosition = Vector2.Lerp(self.actualPosition, self.position, self.easing(self.speed * dt)):add(shakeOffset)
end

function Camera:attach()
    love.graphics.push()

    love.graphics.translate(WIDTH / 2, HEIGHT / 2)
    love.graphics.scale(self.zoom)

    love.graphics.translate(-self.actualPosition.x, -self.actualPosition.y)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera