local blankTex = lg.newImage("assets/images/blank_tex.png", {linear = true})
blankTex:setFilter("nearest", "nearest")
blankTex:setWrap("repeat")

local blankNormal = lg.newImage("assets/images/blank_normal.png", {linear = true})
blankNormal:setWrap("repeat")

local textures = {}

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
--- @overload fun(shader: love.Shader, attributes: MaterialDefinition)
local Material = Object:extend()

Material.BLANK_TEX = blankTex
Material.BLANK_NORMAL = blankNormal


function Material:new(shader, attributes)
    rawset(self, "__attrs", attributes)
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

    lg.setShader(self.shader)

    if self.shader:hasUniform("u_isCanvasEnabled") then
        self.shader:send("u_isCanvasEnabled", lg.getCanvas() ~= nil)
    end
end


--- @param aiMat unknown
--- @param type string
--- @param texIndex integer
--- @param linear boolean
--- @return love.Image?
function Material.GetTexture(aiMat, type, texIndex, linear)
    local path = aiMat:texture_path(type, texIndex)

    if path then
        if not textures[path] then
            textures[path] = lg.newImage("assets/models/"..path, {linear = linear})
        end
        return textures[path]
    end
    return nil
end


return Material