local Object = require "engine.3rdparty.classic.classic"

--- @class BaseLight: Object
---
--- @field position Vector3
--- @field ambient table
--- @field diffuse table
--- @field specular table
--- @field near number
--- @field far number
--- @field enabled boolean
--- @field depthShader love.Shader
--- @field shadowmap love.Texture
---
--- @overload fun(position: Vector3, diffuse: table, specular: table, depthShader: love.Shader): BaseLight
local BaseLight = Object:extend("BaseLight")


function BaseLight:new(position, diffuse, specular, depthShader)
    self.position = position

    self.diffuse = diffuse
    self.specular = specular

    self.depthShader = depthShader

    self.near = 1
    self.far = 15

    self.enabled = true

    self.shadowmap = nil
end


--- @protected
--- @param viewProj Matrix
--- @param mapFace number?
function BaseLight:beginShadowMapping(viewProj, mapFace)
    love.graphics.push("all")

    love.graphics.setCanvas {depthstencil = {self.shadowmap, face = mapFace or 1}}
    love.graphics.clear()
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("none")
    love.graphics.setBlendMode("replace")
    love.graphics.setShader(self.depthShader)

    self.depthShader:send("u_viewProj", "column", viewProj:toFlatTable())
end


--- @protected
function BaseLight:endShadowMapping()
    love.graphics.pop()
end


--- @param meshparts table
function BaseLight:generateShadowMap(meshparts)
    error("Not implemented")
end


--- @param lightingShader love.Shader
function BaseLight:applyLighting(lightingShader)
    error("Not implemented")
end


return BaseLight