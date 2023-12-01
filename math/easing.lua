--- @alias InterpolationFunction fun(v: number): number

--- @type table<string, InterpolationFunction>
local Easing = {}

local easein = {
    linear     = function(v) return v end,
    quadratic  = function(v) return v * v end,
    cubic      = function(v) return v * v * v end,
    quartic    = function(v) return v * v * v * v end,
    quintic    = function(v) return v * v * v * v * v end,
    sine       = function(v) return 1 - math.cos(v * math.pi / 2) end,
    circular   = function(v) return 1 - math.sqrt(1 - v * v) end,
}

for name, inf in pairs(easein) do
    local outf = function(v) return 1 - inf(1 - v) end
    local inoutf = function(v) return (v < 0.5 and inf(v*2) or 1 + outf(v*2)) * 0.5 end
    local outinf = function(v) return (v < 0.5 and outf(v*2) or 1 + inf(v*2)) * 0.5 end

    Easing[name] = inf
    Easing["out_"..name] = outf
    Easing["inout_"..name] = inoutf
    Easing["outin_"..name] = outinf
end

return Easing