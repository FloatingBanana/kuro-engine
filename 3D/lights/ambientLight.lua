local Vector3   = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"

--- @class AmbientLight: BaseLight
---
--- @field color table
--- @overload fun(color: table): AmbientLight
local AmbientLight = BaseLight:extend("AmbientLight")


function AmbientLight:new(color)
    BaseLight.new(self, Vector3(), {0,0,0}, {0,0,0}, nil)

    self.color = color
end


function AmbientLight:generateShadowMap(meshparts)
end


function AmbientLight:applyLighting(lightingShader)
    lightingShader:send("light.color", self.color)
end


function AmbientLight:getLightTypeDefinition()
    return "LIGHT_TYPE_AMBIENT"
end


return AmbientLight