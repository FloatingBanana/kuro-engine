local Object = require "engine.3rdparty.classic.classic"

--- @class BaseLight: Object
---
--- @field position Vector3
--- @field ambient table
--- @field color table
--- @field specular table
--- @field near number
--- @field far number
--- @field enabled boolean
--- @field depthShader love.Shader
--- @field shadowmap love.Texture
---
--- @overload fun(position: Vector3, color: table, specular: table, depthShader: love.Shader): BaseLight
local BaseLight = Object:extend("BaseLight")


function BaseLight:new(position, color, specular, depthShader)
    self.position = position

    self.color = color
    self.specular = specular

    self.depthShader = depthShader

    self.near = 1
    self.far = 15

    self.enabled = true

    self.shadowmap = nil
end


--- @param meshparts table
function BaseLight:generateShadowMap(meshparts)
    love.graphics.push("all")

    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace")
    love.graphics.setShader(self.depthShader)

    self:drawShadows(self.depthShader, meshparts)

    love.graphics.pop()
end


---@param shader love.Shader
---@param meshparts MeshPartConfig[]
function BaseLight:drawShadows(shader, meshparts)
    error("Not implemented")
end


--- @param lightingShader love.Shader
function BaseLight:applyLighting(lightingShader)
    error("Not implemented")
end


---@return string
function BaseLight:getLightTypeDefinition()
    error("Not implemented")
end


return BaseLight