local Vector3   = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"

--- @class AmbientLight: BaseLight
---
--- @field public color number[]
--- @overload fun(color: table): AmbientLight
local AmbientLight = BaseLight:extend("AmbientLight")


function AmbientLight:new(color)
    BaseLight.new(self, BaseLight.LIGHT_TYPE_AMBIENT)

    self.color = color
end


--- @param shader ShaderEffect
function AmbientLight:sendLightData(shader)
    shader:trySendUniform("light.color", self.color)
end

return AmbientLight