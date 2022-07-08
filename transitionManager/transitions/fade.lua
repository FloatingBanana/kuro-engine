local Base = require "engine.transitionManager.transitionBase"
local Fade = Base:extend()

function Fade:new(maxTime, isFadingOut, color)
    Base.new(self, maxTime, isFadingOut)

    self.color = color
end

function Fade:drawFadeIn()
    self.color.alpha = 1 - self.progress

    lg.setColor(self.color)
    lg.rectangle("fill", 0, 0, WIDTH, HEIGHT)
end

function Fade:drawFadeOut()
    self.color.alpha = self.progress

    lg.setColor(self.color)
    lg.rectangle("fill", 0, 0, WIDTH, HEIGHT)
end

return Fade