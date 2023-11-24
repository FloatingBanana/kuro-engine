-- Helper for creating C structs using FFI.
-- If jit is disabled then it falls back to using tables, which are slower.

local ffi = nil
local hasJit = false

if jit and jit.status() then
    ffi = require "ffi"
    hasJit = true
end


---
--- Helper for creating C structs using FFI.
---
--- If JIT is disabled then it falls back to using tables, which are slower.
---
--- @class CStruct
---
--- @field typename ffi.ctype*: The name of this struct
--- @field private _flattable table: temporary storage for this object's data
---
--- @operator call: CStruct
local structmt = {}
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



--- Returns a table array containing the components of this struct sequentialy.
--- This method is used as an easy way to pass structs to shaders.
---
--- DO NOT store this table anywhere, the table returned here is reused internally
--- by all instances of the same struct.
--- @return table
function structmt:toFlatTable()
    for i=1, select("#", self:split()) do
        self._flattable[i] = select(i, self:split())
    end

    return self._flattable
end



--- Returns all the components of this struct.
--- Should be overloaded.
--- @return unknown
function structmt:split()
    error("not implemented")
end


--- Constructor method that will be called as soon as the object is created.
--- Should be overloaded.
function structmt:new()
    error("not implemented")
end



--- Defines a new C struct.
--- This function creates a small piece of C code and compiles it using FFI.
---
--- The C code is: `typedef { <definition> } <structname>;`
--- @param structname string: The struct's type name
--- @param definition string: The struct's definition code
--- @return CStruct: An object representing the struct
local function DefineStruct(structname, definition)
    local struct = setmetatable({typename = structname, _flattable = {}}, structmt)

    if hasJit then
        local code = ("typedef struct {%s} %s;"):format(definition, structname)

        ffi.cdef(code)
        ffi.metatype(structname --[[@as ffi.ctype*]], struct)
    end

    return struct
end

return DefineStruct