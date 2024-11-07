local ModelNode = require "engine.3D.model.modelNode"

---@class ModelArmature: ModelNode
---
---@field public bones table<string, ModelBone>
---@field public rootBones table<string, ModelBone>
---
---@overload fun(model: Model, name: string, localMatrix: Matrix4): ModelArmature
local ModelArmature = ModelNode:extend("ModelArmature")

function ModelArmature:new(model, name, localMatrix)
    ModelNode.new(self, model, name, localMatrix)

    self.bones = {}
    self.rootBones = {}
end

return ModelArmature