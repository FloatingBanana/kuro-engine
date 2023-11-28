local IH = {
    actions = {},
    axis = {}
}

local function anyPressed(buttons)
    for i, key in ipairs(buttons) do
        if (love.keyboard.isDown(key)) then
            return true
        end
    end

    return false
end

function IH.registerAction(name, buttons)
    IH.actions[name] = buttons
end

function IH.registerAxis(name, negative, positive)
    IH.axis[name] = {negative = negative, positive = positive}
end

function IH.getAction(name)
    return anyPressed(IH.actions[name])
end

function IH.getAxis(name)
    local pos = anyPressed(IH.axis[name].positive) and  1 or 0
    local neg = anyPressed(IH.axis[name].negative) and -1 or 0

    return pos + neg
end

return IH