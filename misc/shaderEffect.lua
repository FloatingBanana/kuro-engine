local Object  = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Utils   = require "engine.misc.utils"

local globalCache = {}


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
        local cache = globalCache[self._shadercode] or {}
        globalCache[self._shadercode] = cache

        for defs, shader in pairs(cache) do
            if Utils.isTableEqual(defs, self._defines, false) then
                self._shader = shader
                self._isDirty = false
                return
            end
        end


        local defsCopy = Utils.shallowCopy(self._defines)
        self._shader = Utils.newPreProcessedShader(self._shadercode, defsCopy)
        globalCache[self._shadercode][defsCopy] = self._shader
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



local function convertValue(value)
    if Utils.isType(value, "cstruct") then
        return value:toFlatTable()
    end
    return value
end

---@param name string
---@param ... any
function ShaderEffect:sendUniform(name, ...)
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

    local inUse = self:isInUse()
    self._defines[name] = value
    self._isDirty = true

    if inUse then
        self:use()
    end
end



---@param name string
function ShaderEffect:undefine(name)
    if not self._defines[name] then
        return
    end

    local inUse = self:isInUse()
    self._defines[name] = nil
    self._isDirty = true

    if inUse then
        self:use()
    end
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

    self:trySendUniform("uInvViewMatrix", "column", camera.invViewMatrix)
	self:trySendUniform("uInvProjMatrix", "column", camera.invProjectionMatrix)
	self:trySendUniform("uInvViewProjMatrix", "column", camera.invViewProjectionMatrix)

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
	self:trySendUniform("uVelocityBuffer", renderer.velocityBuffer)
	self:trySendUniform("uColorBuffer", renderer.resultCanvas)

    if renderer.ClassName == "DeferredRenderer" then ---@cast renderer DeferredRenderer
        self:trySendUniform("uGNormal", renderer.gbuffer.normal)
	    self:trySendUniform("uGAlbedoSpecular", renderer.gbuffer.albedoSpec)
    end

    self:sendCameraUniforms(renderer.camera)

    return self
end



---@param config MeshPartConfig
---@return self
function ShaderEffect:sendMeshConfigUniforms(config)
    self:trySendUniform("uWorldMatrix", "column", config.worldMatrix)
    self:trySendUniform("uInverseTransposedWorldMatrix", "column", config.worldMatrix.inverse:transpose())

    if config.animator then
        self:trySendUniform("uBoneMatrices", "column", config.animator.finalMatrices)
    end

    return self
end


return ShaderEffect