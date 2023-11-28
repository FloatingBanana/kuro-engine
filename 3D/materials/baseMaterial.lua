local function sendToShader(shader, uniform, value)
    local sendValue = value

    if not shader:hasUniform(uniform) then
        return
    end

    if type(value) == "cdata" then
        sendValue = value:toFlatTable()

        if value.typename == "matrix" then
            shader:send(uniform, "column", sendValue)
            return
        end
    end

    shader:send(uniform, sendValue)
end


--- @alias MaterialDefinition table<string, {uniform: string, value: any}>

--- @class BaseMaterial: Object
---
--- @field shader love.Shader
--- @field private __attrs MaterialDefinition
--- @field BLANK_TEX love.Image
--- @field BLANK_NORMAL love.Image
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

        if not value then
            print("Attempt to assign nil to '"..key.."' material attribute")
            return
        end

        attr.value = value
        return
    end

    rawset(self, key, value)
end


function Material:apply()
    for name, attr in pairs(rawget(self, "__attrs")) do
        if attr.value then
            sendToShader(self.shader, attr.uniform, attr.value)
        end
    end

    love.graphics.setShader(self.shader)

    if self.shader:hasUniform("u_isCanvasEnabled") then
        self.shader:send("u_isCanvasEnabled", love.graphics.getCanvas() ~= nil)
    end
end


return Material