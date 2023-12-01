local Base = require "engine.transitions.transitionBase"
local Fade = Base:extend()

function Fade:new(maxTime, isFadingOut, color)
    Base.new(self, maxTime, isFadingOut)

    self.color = color
end

function Fade:drawFadeIn()
    self.color[4] = 1 - self.progress

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
end

function Fade:drawFadeOut()
    self.color[4] = self.progress

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
end

return Fade