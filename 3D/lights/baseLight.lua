local Object        = require "engine.3rdparty.classic.classic"
local ShaderEffect  = require "engine.misc.shaderEffect"

local shadowMapRendererShader = ShaderEffect("engine/shaders/3D/defaultVertexShader.vert", "engine/shaders/3D/shadowMapRenderer.frag", {CURRENT_RENDER_PASS = "RENDER_PASS_SHADOWMAPPING"})


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
--- @field public castShadows boolean
--- @field public isStatic boolean
---
--- @overload fun(typeDefinition: LightTypeDefinition): BaseLight
local BaseLight = Object:extend("BaseLight")

BaseLight.LIGHT_TYPE_UNLIT       = 0
BaseLight.LIGHT_TYPE_AMBIENT     = 1
BaseLight.LIGHT_TYPE_DIRECTIONAL = 2
BaseLight.LIGHT_TYPE_SPOT        = 3
BaseLight.LIGHT_TYPE_POINT       = 4


function BaseLight:new(typeDefinition)
    self.typeDefinition = typeDefinition
    self.enabled = true

    self.castShadows = false
    self.isStatic = false
    self.shadowMap = nil
end


---@param size integer
---@param isStatic boolean
---@return self
function BaseLight:setShadowMapping(size, isStatic)
    self.castShadows = true
    self.isStatic = isStatic
    return self
end


---@param meshparts MeshPartConfig[]
function BaseLight:generateShadowMap(meshparts)
    if not self.castShadows then
        return
    end

    self.castShadows = not self.isStatic

    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace")

    shadowMapRendererShader:use()
    shadowMapRendererShader:sendCommonUniforms()
    shadowMapRendererShader:sendUniform("u_lightType", self.typeDefinition)

    self:drawShadows(shadowMapRendererShader, meshparts)
end


---@protected
---@param config MeshPartConfig
---@return boolean
function BaseLight:canMeshCastShadow(config)
    return config.castShadows and (not self.isStatic or config.static)
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function BaseLight:drawShadows(shader, meshparts)
    error("Not implemented")
end


--- @param shader ShaderEffect
--- @param lightUniform string
function BaseLight:sendLightData(shader, lightUniform)
    error("Not implemented")
end




---@param size integer
---@param type love.TextureType
function BaseLight.CreateShadowMapTexture(size, type)
    local shadowMap = love.graphics.newCanvas(size, size, {type = type, format = "depth16", readable = true})
    shadowMap:setFilter("linear", "linear")
    shadowMap:setWrap("clamp")
    shadowMap:setDepthSampleMode("less")

    return shadowMap
end


return BaseLight