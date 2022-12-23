local Dbg = {}

local modstates = {}
function Dbg.wasFileModified(file)
    local currModtime = lfs.getInfo(file, "file").modtime
    local lastModtime = modstates[file]

    modstates[file] = currModtime
    return lastModtime and currModtime ~= lastModtime
end

function Dbg.hotswap(file)
    package.loaded[file] = nil
    return require(file)
end

function Dbg.hotswapWhenModified(file)
    local fullFile = file:gsub("%.", "/")..".lua"

    if Dbg.wasFileModified(fullFile) then
        return Dbg.hotswap(file)
    end
end

return Dbg