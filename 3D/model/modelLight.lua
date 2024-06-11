local ModelNode = require "engine.3D.model.modelNode"

--- @class ModelLight: ModelNode
---
--- @field type "undefined"|"directional"|"spot"|"point"|"ambient"|"area"
---
--- @field ambient number[]
--- @field diffuse number[]
--- @field specular number[]
---
--- @field constant number
--- @field linear number
--- @field quadratic number
---
--- @field innerCone number
--- @field outerCone number
---
--- @field areaLightSize Vector2
---
--- @overload fun(model: Model, name: string, localMatrix: Matrix, aiLightData: table): ModelLight
local Camera = ModelNode:extend("ModelLight")


function Camera:new(model, name, localMatrix, aiLightData)
    ModelNode.new(self, model, name, localMatrix)

    self.type = aiLightData.type

    self.ambient = aiLightData.ambient
    self.diffuse = aiLightData.diffuse
    self.specular = aiLightData.specular

    self.constant = aiLightData.constant
    self.linear = aiLightData.linear
    self.quadratic = aiLightData.quadratic

    self.innerCone = aiLightData.innerCone
    self.outerCone = aiLightData.outerCone

    self.areaLightSize = aiLightData.size
end


return Camera