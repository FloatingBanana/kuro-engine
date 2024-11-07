local ModelNode = require "engine.3D.model.modelNode"

---@class ModelBone: ModelNode
---
---@field public offset Matrix4
---@field public id integer
---
---@overload fun(model: Model, name: string, localMatrix: Matrix4, offset: Matrix4, id: integer): ModelBone
local ModelBone = ModelNode:extend("ModelBone")

function ModelBone:new(model, name, localMatrix, offset, id)
    ModelNode.new(self, model, name, localMatrix)

    self.offset = offset
    self.id = id
end

return ModelBone