local Object     = require "engine.3rdparty.classic.classic"
local Utils      = require "engine.misc.utils"

local globalCache = {}


---@class ShaderEffect: Object
---
---@field private _shadercode string
---@field private _defines table
---@field private _isDirty boolean
---
---@overload fun(vertexshader: string, pixelshader: string, defines: table?): ShaderEffect
---@overload fun(shader: string, defines: table?): ShaderEffect
local ShaderEffect = Object:extend("ShaderEffect")

function ShaderEffect:new(vertexshader, pixelshader, defines)
    if type(pixelshader) ~= "string" then
        defines = pixelshader
        pixelshader = nil
        self._shadercode = vertexshader
    else
        self._shadercode = Utils.combineShaders(vertexshader, pixelshader)
    end

    self._defines = defines or {}
    self._isDirty = true

    self:updateShader()
end



function ShaderEffect:updateShader()
    if self._isDirty then
        local cache = globalCache[self._shadercode] or {}
        globalCache[self._shadercode] = cache

        for defs, shader in pairs(cache) do
            if Utils.isTableEqual(defs, self._defines, false) then
                self.shader = shader
                self._isDirty = false
                return
            end
        end


        local defsCopy = Utils.shallowCopy(self._defines)
        self.shader = Utils.newPreProcessedShader(self._shadercode, defsCopy)
        globalCache[self._shadercode][defsCopy] = self.shader
        self._isDirty = false
    end
end


function ShaderEffect:use()
    self:updateShader()

    if not self:isInUse() then
        love.graphics.setShader(self.shader)
    end
end



---@param name string
---@return boolean
function ShaderEffect:hasUniform(name)
    return self.shader:hasUniform(name)
end



local function convertValue(value)
    if Utils.isType(value, "cstruct") then
        return value:toFlatTable()
    end
    return value
end

---@param name string
---@param ... any
function ShaderEffect:sendUniform(name, ...)
    self:updateShader()

    local argcount = select("#", ...)

    if argcount == 1 then
        if Utils.isType(..., "matrix") then
            self.shader:send(name, "column", convertValue(...))
        else
            self.shader:send(name, convertValue(...))
        end
    elseif argcount == 2 and Utils.isType(select(1, ...), "string") then
        self.shader:send(name, select(1, ...), convertValue(select(2, ...)))
    else
        self.shader:send(name, ...)
    end
end



---@param name string
---@param ... any
---@return boolean
function ShaderEffect:trySendUniform(name, ...)
    if self:hasUniform(name) then
        self:sendUniform(name,...)
        return true
    end
    return false
end



---@param name string
---@param value string|number
---@overload fun(self: ShaderEffect, name: string)
function ShaderEffect:define(name, value)
    value = value or true

    if self._defines[name] == value then
        return
    end

    self._defines[name] = value
    self._isDirty = true

    if self:isInUse() then
        self:updateShader()
        self:use()
    end
end



---@param name string
function ShaderEffect:undefine(name)
    if not self._defines[name] then
        return
    end

    self._defines[name] = nil
    self._isDirty = true

    if self:isInUse() then
        self:updateShader()
        self:use()
    end
end



---@return boolean
function ShaderEffect:isInUse()
    return love.graphics.getShader() == self.shader
end



function ShaderEffect:clone()
    return ShaderEffect(self._shadercode, Utils.shallowCopy(self._defines))
end


return ShaderEffect