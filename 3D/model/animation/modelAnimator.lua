local Vector3    = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local Object     = require "engine.3rdparty.classic.classic"
local newtable   = require "table.new"

local MAX_BONES = 20


--- @class ModelAnimator: Object
---
--- @field public time number
--- @field public isPlaying boolean
--- @field public duration number
--- @field public fps integer
--- @field public finalQuaternions Quaternion[]
--- @field public finalScaling Vector3[]
---
--- @field private animation ModelAnimation
--- @field private armature ModelArmature
--- @field private armatureToModelMatrix Matrix4
---
--- @overload fun(animation: ModelAnimation, armature: ModelArmature, modelOriginalGlobalMatrix: Matrix4): ModelAnimator
local Animator = Object:extend("ModelAnimator")


function Animator:new(animation, armature, modelOriginalGlobalMatrix)
    self.time = 0
    self.isPlaying = false
    self.duration = animation.duration
    self.fps = animation.fps

    self.animation = animation
    self.armature = armature
    self.armatureToModelMatrix = armature:getGlobalMatrix() * modelOriginalGlobalMatrix.inverse

    self.finalQuaternions = newtable(MAX_BONES*2, 0)
    self.finalScaling = newtable(MAX_BONES, 0)

    for i=1, MAX_BONES do
        self.finalQuaternions[i*2-1] = Quaternion.Identity()
        self.finalQuaternions[i*2]   = Quaternion()
        self.finalScaling[i]         = Vector3(1)
    end
end


function Animator:update(dt)
    if self.isPlaying then
        self.time = (self.time + self.fps * dt) % self.duration
    end

    for name, bone in pairs(self.armature.rootBones) do
        self.animation:updateBonesDQS(self.time, self.finalQuaternions, self.finalScaling, bone, self.armatureToModelMatrix)
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