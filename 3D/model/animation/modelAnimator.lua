local Matrix = require "engine.math.matrix"
local Object = require "engine.3rdparty.classic.classic"
local ffi    = require "ffi"
local Quaternion = require "engine.math.quaternion"

local MAX_BONES = 20


--- @class ModelAnimator: Object
---
--- @field public time number
--- @field public isPlaying boolean
--- @field public duration number
--- @field public fps integer
--- @field public finalQuaternions love.ByteData
---
--- @field private animation ModelAnimation
--- @field private armature ModelArmature
--- @field private armatureToModelMatrix Matrix
--- @field private finalQuaternionsPtr ffi.cdata*
---
--- @overload fun(animation: ModelAnimation, armature: ModelArmature, modelOriginalGlobalMatrix: Matrix): ModelAnimator
local Animator = Object:extend("ModelAnimator")


function Animator:new(animation, armature, modelOriginalGlobalMatrix)
    self.time = 0
    self.isPlaying = false
    self.duration = animation.duration
    self.fps = animation.fps

    self.animation = animation
    self.armature = armature
    self.armatureToModelMatrix = armature:getGlobalMatrix() * modelOriginalGlobalMatrix.inverse

    self.finalQuaternions = love.data.newByteData(ffi.sizeof("quaternion") * MAX_BONES*2)
    self.finalQuaternionsPtr = ffi.cast("quaternion*", self.finalQuaternions:getFFIPointer())

    self.finalMatrices = love.data.newByteData(ffi.sizeof("matrix") * MAX_BONES)
    self.finalMatricesPtr = ffi.cast("matrix*", self.finalMatrices:getFFIPointer())

    for i=0, MAX_BONES-1 do
        self.finalQuaternionsPtr[i*2]   = Quaternion.Identity()
        self.finalQuaternionsPtr[i*2+1] = Quaternion()
        self.finalMatricesPtr[i] = Matrix.Identity()
    end
end


function Animator:update(dt)
    if self.isPlaying then
        self.time = (self.time + self.fps * dt) % self.duration
    end

    for name, bone in pairs(self.armature.rootBones) do
        self.animation:updateBonesDQS(self.time, self.finalQuaternionsPtr, self.finalMatricesPtr, bone, self.armatureToModelMatrix)
    end
end


function Animator:stop()
    self.isPlaying = false
    self.time = 0
end


function Animator:play()
    self.isPlaying = true
end


function Animator:pause()
    self.isPlaying = false
end


return Animator