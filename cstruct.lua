-- Helper for creating C structs using FFI.
-- If jit is disabled then it falls back to using tables, which are slower.

---@diagnostic disable: param-type-mismatch

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

-- Copy data to a shared flat table and returns it.
-- This is mostly for passing data to shaders without
-- having to create an intermediate table every time.
function structmt:toFlatTable()
    for i=1, select("#", self:split()) do
        self._flattable[i] = select(i, self:split())
    end

    return self._flattable
end

local function DefineStruct(structname, definition)
    local struct = setmetatable({typename = structname, _flattable = {}}, structmt)

    if hasJit then
        local code = ("typedef struct {%s} %s;"):format(definition, structname)

        ffi.cdef(code)
        ffi.metatype(structname, struct)
    end

    return struct
end

return DefineStruct