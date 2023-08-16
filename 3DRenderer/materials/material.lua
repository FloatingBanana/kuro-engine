local blankTexData = love.image.newImageData(2,2)
blankTexData:setPixel(0, 0, 0, 0, 0, 1)
blankTexData:setPixel(1, 0, 1, 0, 1, 1)
blankTexData:setPixel(1, 1, 0, 0, 0, 1)
blankTexData:setPixel(0, 1, 1, 0, 1, 1)

local blankTex = lg.newImage(blankTexData)
blankTex:setFilter("nearest", "nearest")
blankTex:setWrap("repeat")

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

--- @class Material: Object
---
--- @field shader love.Shader
--- @field private __attrs MaterialDefinition
---
--- @overload fun(shader: love.Shader, attributes: MaterialDefinition)
local Material = Object:extend()


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
end


--- @param mat unknown
--- @param type string
--- @param texIndex integer
--- @param linear boolean
--- @return love.Image?
function Material.GetTexture(mat, type, texIndex, linear)
    local path = mat:texture_path(type, texIndex)

    if path then
        if not textures[path] then
            textures[path] = lg.newImage("assets/models/"..path, {linear = linear})
        end

        return textures[path]
    else
        return blankTex
    end
end


return Material