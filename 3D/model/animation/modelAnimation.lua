local Matrix = require "engine.math.matrix"
local AnimationNode = require "engine.3D.model.animation.modelAnimationNode"
local Animator = require "engine.3D.model.animation.modelAnimator"
local Object   = require "engine.3rdparty.classic.classic"
local Quaternion = require "engine.math.quaternion"


--- @class ModelAnimation: Object
---
--- @field public model Model
--- @field public name string
--- @field public duration number
--- @field public fps integer
--- @field public animNodes table<string, ModelAnimationNode>
--- @field public time number
--- @field public isPlaying boolean
---
--- @overload fun(model: Model, animData: table): ModelAnimation
local Anim = Object:extend("ModelAnimation")


function Anim:new(model, animData)
    self.model = model
    self.name = animData.name
    self.duration = animData.duration
    self.fps = animData.fps
    self.animNodes = {}

    for name, animNodeData in pairs(animData.nodes) do
        self.animNodes[name] = AnimationNode(animNodeData)
    end
end


---@param armature ModelArmature
---@param modelOriginalGlobalMatrix Matrix
---@return ModelAnimator
function Anim:getNewAnimator(armature, modelOriginalGlobalMatrix)
    return Animator(self, armature, modelOriginalGlobalMatrix)
end


--- @param time number
--- @param dqListPtr ffi.cdata*
--- @param bone ModelBone
--- @param parentTransform Matrix
function Anim:updateBonesDQS(time, dqListPtr, bone, parentTransform)
    local transform = bone.localMatrix
    local animNode = self.animNodes[bone.name]

    if animNode then
        local position, rotation, scale = animNode:getInterpolated(time)
        transform = Matrix.CreateTransformationMatrix(rotation, scale, position)
    end

    local globalTransform = transform * parentTransform

    local finalBoneTransform = bone.offset * globalTransform
    local rotation = finalBoneTransform.rotation

    dqListPtr[bone.id*2]   = rotation
    dqListPtr[bone.id*2+1] = Quaternion.CreateDualQuaternionTranslation(rotation, finalBoneTransform.translation)

    for i, child in ipairs(bone.children) do
        ---@cast child ModelBone
        self:updateBonesDQS(time, dqListPtr, child, globalTransform)
    end
end


--- @param time number
--- @param matrixList ffi.cdata*
--- @param bone ModelBone
--- @param parentTransform Matrix
function Anim:updateBonesLBS(time, matrixList, bone, parentTransform)
    local transform = bone.localMatrix
    local animNode = self.animNodes[bone.name]

    if animNode then
        local position, rotation, scale = animNode:getInterpolated(time)
        transform = Matrix.CreateTransformationMatrix(rotation, scale, position)
    end

    local globalTransform = transform * parentTransform

    if bone then
        matrixList[bone.id] = bone.offset * globalTransform
    end

    for i, child in ipairs(bone.children) do
        ---@cast child ModelBone
        self:updateBonesLBS(time, matrixList, child, globalTransform)
    end
end


return Anim