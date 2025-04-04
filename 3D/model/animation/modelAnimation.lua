local Matrix4 = require "engine.math.matrix4"
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
---@param modelOriginalGlobalMatrix Matrix4
---@return ModelAnimator
function Anim:getNewAnimator(armature, modelOriginalGlobalMatrix)
    return Animator(self, armature, modelOriginalGlobalMatrix)
end


--- @param time number
--- @param dqList Quaternion[]
--- @param scaleLists Vector3[]
--- @param bone ModelBone
--- @param parentTransform Matrix4
function Anim:updateBonesDQS(time, dqList, scaleLists, bone, parentTransform)
    local transform = bone.localMatrix
    local animNode = self.animNodes[bone.name]

    if animNode then
        local position, rotation, scale = animNode:getInterpolated(time)
        transform = Matrix4.CreateTransformationMatrix(rotation, scale, position)
    end

    local globalTransform = transform * parentTransform
    local finalBoneTransform = bone.offset * globalTransform
    local translation, scale, rotation = finalBoneTransform:decompose()
    local id = bone.id+1

    dqList[id*2-1] = rotation
    dqList[id*2]   = Quaternion.CreateDualQuaternionTranslation(rotation, translation)
    scaleLists[id] = scale

    for i, child in ipairs(bone.children) do
        ---@cast child ModelBone
        self:updateBonesDQS(time, dqList, scaleLists, child, globalTransform)
    end
end


--- @param time number
--- @param matrixList Matrix4
--- @param bone ModelBone
--- @param parentTransform Matrix4
function Anim:updateBonesLBS(time, matrixList, bone, parentTransform)
    local transform = bone.localMatrix
    local animNode = self.animNodes[bone.name]

    if animNode then
        local position, rotation, scale = animNode:getInterpolated(time)
        transform = Matrix4.CreateTransformationMatrix(rotation, scale, position)
    end

    local globalTransform = transform * parentTransform

    if bone then
        matrixList[bone.id+1] = bone.offset * globalTransform
    end

    for i, child in ipairs(bone.children) do
        ---@cast child ModelBone
        self:updateBonesLBS(time, matrixList, child, globalTransform)
    end
end


return Anim