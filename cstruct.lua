-- Helper for creating C structs using FFI.
-- If jit is disabled then it falls back to using tables, which are slower.

local ffi = nil
local hasJit = false

if jit and jit.status() then
    ffi = require "ffi"
    hasJit = true
end

local structmt = {
    new = NULLFUNC -- constructor
}
setmetatable(structmt, structmt)

function structmt:__call(...)
    local instance = nil

    if hasJit then
        instance = ffi.new(self.typename)
    else
        instance = setmetatable({}, self)
    end

    ---@diagnostic disable-next-line: undefined-field
    instance:new(...)
    return instance
end

function structmt:__index(key)
    return rawget(structmt, key)
end

local function DefineStruct(structname, definition)
    local struct = setmetatable({typename = structname}, structmt)

    if hasJit then
        local code = ("typedef struct {%s} %s;"):format(definition, structname)
        
        ffi.cdef(code)
        ffi.metatype(structname, struct)
    end

    return struct
end

return DefineStruct