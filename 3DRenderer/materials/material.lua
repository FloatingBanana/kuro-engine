local Material = Object:extend()

function Material:new(shader, attributes)
    rawset(self, "__attrs", attributes)
    self.shader = shader

    -- Small trick to properly setup the initial values
    for key, attr in pairs(attributes) do
        self[key] = attr.value
    end
end

function Material:__index(key)
    if rawget(self, "__attrs") and self.__attrs[key] then
        return self.__attrs[key].value
    end

    return Material[key]
end

function Material:__newindex(key, value)
    if rawget(self, "__attrs") and self.__attrs[key] then
        local attr = self.__attrs[key]

        if not value then
            print("Attempt to assign nil to '"..key.."' material attribute")
            return
        end

        attr.value = value
        local sendValue = value

        if type(value) == "cdata" then
            sendValue = value:toFlatTable()

            local ffi = require "ffi"
            if ffi.istype("matrix", value) then
                self.shader:send(attr.uniform, "column", sendValue)
                return
            end
        end

        self.shader:send(attr.uniform, sendValue)
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material