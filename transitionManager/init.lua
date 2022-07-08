local TM = {
    current = nil,
    isPlaying = false,
}

function TM.play(transition)
    TM.current = transition
    TM.isPlaying = true
end

function TM.update(dt)
    if TM.isPlaying then
        local current = TM.current

        current.time = current.time + dt
        current.progress = current.time / current.maxTime
        current:update(dt)

        if current.time >= current.maxTime then
            current:onStop()
            TM.current = nil
            TM.isPlaying = false
        end
    end
end

function TM.draw()
    if TM.isPlaying then
        local current = TM.current

        if current.isFadingOut then
            current:drawFadeOut()
        else
            current:drawFadeIn()
        end
    end
end

return TM