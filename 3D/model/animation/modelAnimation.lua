local Matrix = require "engine.math.matrix"
local AnimationNode = require "engine.3D.model.animation.modelAnimationNode"
local Animator = require "engine.3D.model.animation.modelAnimator"
local Object   = require "engine.3rdparty.classic.classic"


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


---@param armature ModelNode
---@param modelOriginalGlobalMatrix Matrix
---@return ModelAnimator
function Anim:getNewAnimator(armature, modelOriginalGlobalMatrix)
    return Animator(self, armature, modelOriginalGlobalMatrix)
end


--- @param time number
--- @param matrixList ffi.cdata*
--- @param node ModelNode
--- @param parentTransform Matrix
--- @param armatureToModelMatrix Matrix
function Anim:updateBones(time, matrixList, node, parentTransform, armatureToModelMatrix)
    local transform = node.localMatrix
    local animNode = self.animNodes[node.name]

    if animNode then
        local position, rotation, scale = animNode:getInterpolated(time)
        transform = Matrix.CreateTransformationMatrix(rotation, scale, position)
    end

    local bone = self.model.boneInfos[node.name]
    local globalTransform = transform * parentTransform

    if bone then
        local index = bone.id
        matrixList[index] = (bone.offset * globalTransform):multiply(armatureToModelMatrix)
    end

    for i, child in ipairs(node.children) do
        self:updateBones(time, matrixList, child, globalTransform, armatureToModelMatrix)
    end
end


return Anim