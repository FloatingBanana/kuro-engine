local Object = require "engine.3rdparty.classic.classic"
local Utils = require "engine.misc.utils"

--- @alias MaterialDefinition table<string, {uniform: string, value: any}>

--- @class BaseMaterial: Object
---
--- @field shader love.Shader
--- @field private __attrs MaterialDefinition
---
--- @overload fun(model: Model, shader: love.Shader, attributes: MaterialDefinition)
local Material = Object:extend()


function Material:new(model, shader, attributes)
    rawset(self, "__attrs", attributes)
    self.model = model
    self.shader = shader
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
    if rawget(self, "__attrs") and self.__attrs[key] then
        local attr = self.__attrs[key]

        if rawequal(value, nil) then
            print("Attempt to assign nil to '"..key.."' material attribute")
            return
        end

        attr.value = value
        return
    end

    rawset(self, key, value)
end


---@returned BaseMaterial
function Material:duplicate()
    return Material(self.model, self.shader, Utils.deepCopy(self.__attrs))
end


function Material:apply()
    for name, attr in pairs(rawget(self, "__attrs")) do
        if attr.value then
            if Utils.getType(attr.value) == "matrix" then
                Utils.trySendUniform(self.shader, attr.uniform, "column", attr.value:toFlatTable())
            elseif type(attr.value) == "cdata" then
                Utils.trySendUniform(self.shader, attr.uniform, attr.value:toFlatTable())
            else
                Utils.trySendUniform(self.shader, attr.uniform, attr.value)
            end
        end
    end

    love.graphics.setShader(self.shader)

    if self.shader:hasUniform("u_isCanvasEnabled") then
        self.shader:send("u_isCanvasEnabled", love.graphics.getCanvas() ~= nil)
    end
end


return Material