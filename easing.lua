local calcs = {
    linear    = function(v) return v end,
    quadratic = function(v) return v * v end,
    cubic     = function(v) return v * v * v end,
    quartic   = function(v) return v * v * v * v end,
    quintic   = function(v) return v * v * v * v * v end,
    sine      = function(v) return 1 - math.cos(v * math.pi / 2) end,
    circular  = function(v) return 1 - math.sqrt(1 - v * v) end
}

local Easing = {
    out = {}
}

for name, func in pairs(calcs) do
    -- in
    Easing[name] = function(a, b, t)
        return a + (b - a) * func(t)
    end

    -- out
    Easing.out[name] = function(a, b, t)
        -- FIXME: unecessary complex calculation
        return a + (b - a) * (1 - func(1 - t))
    end
end


return Easing