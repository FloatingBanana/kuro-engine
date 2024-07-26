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
---
--- @overload fun(typeDefinition: LightTypeDefinition, castShadows: boolean): BaseLight
local BaseLight = Object:extend("BaseLight")

BaseLight.LIGHT_TYPE_UNLIT       = 0
BaseLight.LIGHT_TYPE_AMBIENT     = 1
BaseLight.LIGHT_TYPE_DIRECTIONAL = 2
BaseLight.LIGHT_TYPE_SPOT        = 3
BaseLight.LIGHT_TYPE_POINT       = 4


function BaseLight:new(typeDefinition, castShadows)
    self.typeDefinition = typeDefinition
    self.enabled = true

    self.castShadows = castShadows
    self.shadowMap = nil
end


---@param size integer
---@param type love.TextureType
function BaseLight:createShadowMapTexture(size, type)
    if self.castShadows then
        self.shadowMap = love.graphics.newCanvas(size, size, {type = type, format = "depth16", readable = true})
        self.shadowMap:setFilter("linear", "linear")
        self.shadowMap:setWrap("clamp")
        self.shadowMap:setDepthSampleMode("less")
    end
end


---@param meshparts MeshPartConfig[]
function BaseLight:generateShadowMap(meshparts)
    if not self.castShadows then
        return
    end

    love.graphics.push("all")

    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace")

    shadowMapRendererShader:define("CURRENT_LIGHT_TYPE", self.typeDefinition)
    shadowMapRendererShader:use()
    shadowMapRendererShader:sendCommonUniforms()

    self:drawShadows(shadowMapRendererShader, meshparts)

    love.graphics.pop()
end


---@param shader ShaderEffect
---@param meshparts MeshPartConfig[]
function BaseLight:drawShadows(shader, meshparts)
    error("Not implemented")
end


--- @param shader ShaderEffect
function BaseLight:sendLightData(shader)
    error("Not implemented")
end


return BaseLight