local Object  = require "engine.3rdparty.classic.classic"
local Vector2 = require "engine.math.vector2"
local Utils   = require "engine.misc.utils"

--- @alias MaterialDefinition table<string, {uniform: string, value: any}>

--- @class BaseMaterial: Object
---
--- @field DefaultColorTex love.Image
--- @field DefaultNormalTex love.Image
--- @field DefaultOneTex love.Image
--- @field DefaultZeroTex love.Image
---
--- @field public shader ShaderEffect
---
--- @field private __attrs MaterialDefinition
---
--- @overload fun(attributes: MaterialDefinition, shader: ShaderEffect): BaseMaterial
local Material = Object:extend("BaseMaterial")


local defaultColorTexData = love.data.decode("data", "base64", "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAQSURBVBhXY/gPhBDwn+E/ABvyA/1Bas9NAAAAAElFTkSuQmCC")
Material.DefaultColorTex = love.graphics.newImage(defaultColorTexData, {linear = true})
Material.DefaultNormalTex = Utils.newColorImage(Vector2(1), {.5,.5,1,1})
Material.DefaultZeroTex = Utils.newColorImage(Vector2(1), {0,0,0,1})
Material.DefaultOneTex = Utils.newColorImage(Vector2(1), {1,1,1,1})

Material.DefaultColorTex:setWrap("repeat")
Material.DefaultColorTex:setFilter("nearest", "nearest")


function Material:new(attributes, shader)
    self.shader = shader
    self.__attrs = attributes
end


--- @private
function Material:__index(key)
    if rawget(self, "__attrs") and self.__attrs[key] then
        return self.__attrs[key].value
    end

    return Material[key]
end


--- @private
function Material:__newindex(key, value)
    if self.__attrs and self.__attrs[key] then
        local attr = self.__attrs[key]

        if rawequal(value, nil) then
            print("Attempt to assign nil to '"..key.."' material attribute")
            return
        end

        attr.value = value
    else
        rawset(self, key, value)
    end
end


---@param matData table
---@param model Model
function Material:loadMaterialData(matData, model)
    error("Not implemented")
end


---@returned BaseMaterial
function Material:clone()
    return setmetatable(Material(Utils.deepCopy(self.__attrs), self.shader), getmetatable(self))
end


---@param shader ShaderEffect
---@overload fun()
function Material:apply(shader)
    for name, attr in pairs(rawget(self, "__attrs")) do
        if attr.value then
            (shader or self.shader):trySendUniform(attr.uniform, attr.value)
        end
    end
end


---@param light BaseLight
---@overload fun()
function Material:setLight(light)
    if light then
        if light.shadowMap then
            self.shader:undefine("MATERIAL_DISABLE_SHADOWS")
        else
            self.shader:define("MATERIAL_DISABLE_SHADOWS")
        end

        self.shader:define("CURRENT_LIGHT_TYPE", light.typeDefinition)
        light:sendLightData(self.shader, "u_light")
    else
        self.shader:define("CURRENT_LIGHT_TYPE", "LIGHT_TYPE_UNLIT")
    end
end


---@param pass "forward"|"gbuffer"|"lightpass"|"depth"|"shadowmapping"
---@return BaseMaterial
function Material:setRenderPass(pass)
    local def =
        pass == "forward"       and "RENDER_PASS_FORWARD"            or
        pass == "gbuffer"       and "RENDER_PASS_DEFERRED"           or
        pass == "lightpass"     and "RENDER_PASS_DEFERRED_LIGHTPASS" or
        pass == "depth"         and "RENDER_PASS_DEPTH_PREPASS"      or
        pass == "shadowmapping" and "RENDER_PASS_SHADOWMAPPING"      or nil

    self.shader:define("CURRENT_RENDER_PASS", def)

    if pass == "depth" then
        self.shader:undefine("CURRENT_LIGHT_TYPE")
    end

    return self
end


---@type love.PixelFormat[]
Material.GBufferLayout = {}


return Material