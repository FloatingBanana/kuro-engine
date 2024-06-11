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
--- @field private __attrs MaterialDefinition
---
--- @overload fun(attributes: MaterialDefinition)
local Material = Object:extend("BaseMaterial")


local defaultColorTexData = love.data.decode("data", "base64", "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAQSURBVBhXY/gPhBDwn+E/ABvyA/1Bas9NAAAAAElFTkSuQmCC")
Material.DefaultColorTex = love.graphics.newImage(defaultColorTexData, {linear = true})
Material.DefaultNormalTex = Utils.newColorImage(Vector2(1), {.5,.5,1,1})
Material.DefaultZeroTex = Utils.newColorImage(Vector2(1), {0,0,0,1})
Material.DefaultOneTex = Utils.newColorImage(Vector2(1), {1,1,1,1})

Material.DefaultColorTex:setWrap("repeat")
Material.DefaultColorTex:setFilter("nearest", "nearest")


function Material:new(attributes)
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


---@returned BaseMaterial
function Material:clone()
    return Material(Utils.deepCopy(self.__attrs))
end


function Material:apply(shader)
    for name, attr in pairs(rawget(self, "__attrs")) do
        if attr.value then
            shader:trySendUniform(attr.uniform, attr.value)
        end
    end
end


return Material