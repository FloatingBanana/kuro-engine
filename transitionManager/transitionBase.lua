local TransitionBase = Object:extend()

function TransitionBase:new(maxTime, isFadingOut)
    self.time = 0
    self.progress = 0
    self.maxTime = maxTime
    self.isFadingOut = isFadingOut
end

TransitionBase.update = NULLFUNC
TransitionBase.drawFadeIn = NULLFUNC
TransitionBase.drawFadeOut = NULLFUNC
TransitionBase.onStop = NULLFUNC

return TransitionBase