local Object  = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Matrix  = require "engine.math.matrix"

---@alias LightTypeDefinition
---|`BaseLight.LIGHT_TYPE_UNLIT`
---|`BaseLight.LIGHT_TYPE_AMBIENT`
---|`BaseLight.LIGHT_TYPE_DIRECTIONAL`
---|`BaseLight.LIGHT_TYPE_SPOT`
---|`BaseLight.LIGHT_TYPE_POINT`

--- @class BaseLight: Object
---
--- @field public shadowMap love.Texture
--- @field public typeDefinition LightTypeDefinition
--- @field public enabled boolean
--- @field private depthShader love.Shader
---
--- @overload fun(typeDefinition: LightTypeDefinition, depthShader: love.Shader): BaseLight
local BaseLight = Object:extend("BaseLight")

BaseLight.LIGHT_TYPE_UNLIT       = 0
BaseLight.LIGHT_TYPE_AMBIENT     = 1
BaseLight.LIGHT_TYPE_DIRECTIONAL = 2
BaseLight.LIGHT_TYPE_SPOT        = 3
BaseLight.LIGHT_TYPE_POINT       = 4


function BaseLight:new(typeDefinition, depthShader)
    self.typeDefinition = typeDefinition
    self.shadowMap = nil

    self.enabled = true
    self.depthShader = depthShader
end


---@param size integer
---@param type love.TextureType
function BaseLight:createShadowMapTexture(size, type)
    self.shadowmap = love.graphics.newCanvas(size, size, {type = type, format = "depth16", readable = true})
    self.shadowmap:setFilter("linear", "linear")
    self.shadowmap:setWrap("clamp")
    self.shadowmap:setDepthSampleMode("less")
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


--- @param shader ShaderEffect
function BaseLight:sendLightData(shader)
    error("Not implemented")
end


return BaseLight