local Object  = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Matrix3 = require "engine.math.matrix3"
local Utils   = require "engine.misc.utils"
local ffi     = require "ffi"


---@class ShaderEffect: Object
---
---@field public shader love.Shader
---@field private _shader love.Shader
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

    self._shader = nil
    self._defines = defines or {}
    self._isDirty = true
    self._cache = {}

    self:_updateShader()
end



---@private
function ShaderEffect:__index(key)
    if key == "shader" then
        self:_updateShader()
        return self._shader
    end

    return ShaderEffect[key]
end


---@private
function ShaderEffect:_updateShader()
    if self._isDirty then
        for defs, shader in pairs(self._cache) do
            if Utils.isTableEqual(defs, self._defines, false) then
                self._shader = shader
                self._isDirty = false
                return
            end
        end


        local defsCopy = Utils.shallowCopy(self._defines)
        self._shader = Utils.newPreProcessedShader(self._shadercode, defsCopy)
        self._cache[defsCopy] = self._shader
        self._isDirty = false
    end
end



function ShaderEffect:use()
    if not self:isInUse() then
        love.graphics.setShader(self.shader)
    end
end



---@param name string
---@return boolean
function ShaderEffect:hasUniform(name)
    return self.shader:hasUniform(name)
end



local uData = love.data.newByteData(4*16)
local ptrCache = {}

---@param ctype ffi.ctype*
---@param count integer
local function getArrayPtr(ctype, count)
    local size = ffi.sizeof(ctype) * count

    if uData:getSize() < size then
        uData:release()
        uData = love.data.newByteData(size)
        ptrCache = {}
    end

    local ptr = ptrCache[ctype] or ffi.cast(ctype.."*", uData:getFFIPointer())
    ptrCache[ctype] = ptr

    return ptr, size
end


---@param name string
---@param ... any
---@overload fun(self: ShaderEffect, name: string, matLayout: love.MatrixLayout, ...)
function ShaderEffect:sendUniform(name, ...)
    local argcount = select("#", ...)
    local matLayout = select(1, ...)
    local firstIndex = (type(matLayout) == "string" and 2 or 1)
    local first = select(firstIndex, ...)

    if Utils.isType(first, "cstruct") then
        local ptr, size = getArrayPtr(first.typename, argcount - firstIndex + 1)

        for i = firstIndex, argcount do
            ptr[i - firstIndex] = select(i, ...)
        end

        if firstIndex == 2 then
            self.shader:send(name, matLayout, uData, 0, size)
        else
            self.shader:send(name, uData, 0, size)
        end
    else
        self.shader:send(name, ...)
    end
end



---@param name string
---@param ... any
---@return boolean
---@overload fun(self: ShaderEffect, name: string, matLayout: love.MatrixLayout, ...): boolean
function ShaderEffect:trySendUniform(name, ...)
    if self:hasUniform(name) and ... then
        self:sendUniform(name, ...)
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
end



---@param name string
function ShaderEffect:undefine(name)
    if not self._defines[name] then
        return
    end

    self._defines[name] = nil
    self._isDirty = true
end



---@return boolean
function ShaderEffect:isInUse()
    return love.graphics.getShader() == self.shader
end



---@return ShaderEffect
function ShaderEffect:clone()
    return ShaderEffect(self._shadercode, Utils.shallowCopy(self._defines))
end



---@return self
function ShaderEffect:sendCommonUniforms()
    self:trySendUniform("uTime", love.timer.getTime())
    self:trySendUniform("uDeltaTime", love.timer.getDelta())
	self:trySendUniform("uIsCanvasActive", love.graphics.getCanvas() ~= nil)

    return self
end



---@param camera Camera3D
---@return self
function ShaderEffect:sendCameraUniforms(camera)
    self:trySendUniform("uViewMatrix", "column", camera.viewMatrix)
	self:trySendUniform("uProjMatrix", "column", camera.projectionMatrix)
    self:trySendUniform("uViewProjMatrix", "column", camera.viewProjectionMatrix)

    if self:hasUniform("uInvViewMatrix") then
        self:sendUniform("uInvViewMatrix", "column", camera.viewMatrix:invert())
    end
    if self:hasUniform("uInvProjMatrix") then
        self:sendUniform("uInvProjMatrix", "column", camera.projectionMatrix:invert())
    end
    if self:hasUniform("uInvViewProjMatrix") then
        self:sendUniform("uInvViewProjMatrix", "column", camera.viewProjectionMatrix:invert())
    end

    self:trySendUniform("uNearPlane", camera.nearPlane)
    self:trySendUniform("uFarPlane", camera.farPlane)
    self:trySendUniform("uViewPosition", camera.position)
	self:trySendUniform("uViewDirection", Vector3(0,0,1):transform(camera.rotation))

    return self
end



---@param renderer BaseRenderer
---@return self
function ShaderEffect:sendRendererUniforms(renderer)
    self:trySendUniform("uDepthBuffer", renderer.depthCanvas)
	self:trySendUniform("uColorBuffer", renderer.resultCanvas)

    return self
end



---@param config MeshPartConfig
---@return self
function ShaderEffect:sendMeshConfigUniforms(config)
    self:trySendUniform("uWorldMatrix", "column", config.worldMatrix)

    if self:hasUniform("uInverseTransposedWorldMatrix") then
        self:sendUniform("uInverseTransposedWorldMatrix", "column", Matrix3.CreateFromMatrix4(config.worldMatrix):invert():transpose())
    end

    if config.animator then
        self:trySendUniform("uBoneQuaternions", unpack(config.animator.finalQuaternions))
        self:trySendUniform("uBoneScaling", unpack(config.animator.finalScaling))
        self:trySendUniform("uHasAnimation", true)
    else
        self:trySendUniform("uHasAnimation", false)
    end

    return self
end


return ShaderEffect