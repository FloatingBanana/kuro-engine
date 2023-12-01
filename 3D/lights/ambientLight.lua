local Vector3   = require "engine.math.vector3"
local BaseLight = require "engine.3D.lights.baseLight"

--- @class AmbientLight: BaseLight
---
--- @field color table
--- @overload fun(color: table): AmbientLight
local AmbientLight = BaseLight:extend()


function AmbientLight:new(color)
    BaseLight.new(self, Vector3(), {0,0,0}, {0,0,0}, nil)

    self.color = color
end


function AmbientLight:generateShadowMap(meshparts)
end


function AmbientLight:applyLighting(lightingShader)
    lightingShader:send("light.ambient", self.color)
end


return AmbientLight