local ModelNode = require "engine.3DRenderer.model.modelNode"

--- @class ModelMesh: ModelNode
---
--- @field parts MeshPart[]
--- @field transformation Matrix
--- @field materials BaseMaterial[]
---
--- @overload fun(model: Model, name: string, localMatrix: Matrix, meshparts: MeshPart[], parent: ModelNode?): ModelMesh
local Mesh = ModelNode:extend()


function Mesh:new(model, name, localMatrix, meshparts, parent)
    ModelNode.new(self, model, name, localMatrix, parent)

    self.parts = meshparts
    self.materials = {}

    for i, part in ipairs(meshparts) do
        self.materials[i] = part.material
    end
end


function Mesh:draw()
    for i, part in ipairs(self.parts) do
        part:draw()
    end
end


return Mesh