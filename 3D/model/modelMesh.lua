local ModelNode = require "engine.3D.model.modelNode"

--- @class ModelMesh: ModelNode
---
--- @field parts MeshPart[]
--- @field materials BaseMaterial[]
---
--- @overload fun(model: Model, name: string, localMatrix: Matrix, meshparts: MeshPart[]): ModelMesh
local Mesh = ModelNode:extend("ModelMesh")


function Mesh:new(model, name, localMatrix, meshparts)
    ModelNode.new(self, model, name, localMatrix)

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