local baseEffect = Object:extend()

function baseEffect:deferredPreRender(device, shader, gbuffer, view, projection)

end

function baseEffect:applyPostRender(device, canvas, view, projection)
    return canvas
end

return baseEffect