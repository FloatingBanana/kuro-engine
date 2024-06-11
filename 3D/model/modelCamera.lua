local ModelNode = require "engine.3D.model.modelNode"

--- @class ModelCamera: ModelNode
---
--- @field fov number
--- @field aspectRation number
--- @field nearPlane number
--- @field farPlane number
--- @field isOrthographic boolean
--- @field orthographicWidth number
---
--- @overload fun(model: Model, name: string, localMatrix: Matrix, aiCameraData: table): ModelCamera
local Camera = ModelNode:extend("ModelCamera")


function Camera:new(model, name, localMatrix, aiCameraData)
    ModelNode.new(self, model, name, localMatrix)

    self.fov = aiCameraData.fov
    self.aspectRatio = aiCameraData.aspectRatio
    self.nearPlane = aiCameraData.nearPlane
    self.farPlane = aiCameraData.farPlane
    self.isOrthographic = aiCameraData.orthoWidth > 0
    self.orthographicWidth = aiCameraData.orthoWidth
end


return Camera