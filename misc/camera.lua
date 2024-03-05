local Easing  = require "engine.math.easing"
local Rect    = require "engine.math.rect"
local Vector2 = require "engine.math.vector2"
local Timer   = require "engine.misc.timer"
local Object  = require "engine.3rdparty.classic.classic"

---@class Camera: Object
---
---@field public position Vector2
---@field public actualPosition Vector2
---@field public zoom number
---@field public easing InterpolationFunction
---@field public speed number
---@field private _shakeTimer Timer
---@field private _shakeShiftTimer Timer
---@field private _shakeIntensity number
---
---@overload fun(position: Vector2, zoom: number): Camera
local Camera = Object:extend("Camera")

function Camera:new(position, zoom)
    self.position = position
    self.actualPosition = position
    self.zoom = zoom

    self.easing = Easing.linear
    self.speed = 100

    self._shakeTimer = Timer(0, 0, false)
    self._shakeShiftTimer = Timer(0, 0, true)
    self._shakeIntensity = 0
end


---@return Rect
function Camera:getBounds()
    local size = SCREENSIZE * (1 / self.zoom)
    local topleft = self.position - (size / 2)

    return Rect(topleft, size)
end


---@param pos Vector2
---@return Vector2
function Camera:toWorld(pos)
    return self.position - CENTERPOS / self.zoom + pos / self.zoom
end

---@param easing InterpolationFunction
---@param speed number
function Camera:setInterpolation(easing, speed)
    self.easing = easing
    self.speed = speed
end


---@param time number
---@param intensity number
---@param shakeSpeed number
function Camera:shake(time, intensity, shakeSpeed)
    self._shakeTimer.duration = time
    self._shakeShiftTimer.duration = shakeSpeed
    self._shakeIntensity = intensity

    self._shakeTimer:restart():play()
    self._shakeShiftTimer:restart():play()
end


---@param dt number
function Camera:update(dt)
    local shakeOffset = Vector2()

    if self._shakeTimer:update(dt).running then
        if self._shakeShiftTimer:update(dt).justEnded then
            local int = 1 - (self._shakeTimer.time / self._shakeTimer.duration)

            shakeOffset.x = math.random(-int, int) * self._shakeIntensity
            shakeOffset.y = math.random(-int, int) * self._shakeIntensity
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