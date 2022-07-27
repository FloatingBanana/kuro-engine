local Material = Object:extend()

function Material:new(attributes)
    self.attributes = attributes
    self.shader = lg.newShader("engine/3DRenderer/shaders/diffuse.glsl")

    for i=1, 3 do
        local textureSlot = select(i, "ambientTexture", "diffuseTexture", "specularTexture")

        if attributes[textureSlot] then
            self[textureSlot] = lg.newImage(attributes[textureSlot].texture)
        end
    end
end

-- function Material:__index(key)
--     if Material[key] then return Material[key] end

--     if self.attributes[key] then
--         return self.attributes[key]
--     end
-- end

function Material:__newindex(key, value)
    if self.attributes and self.attributes[key] then
        self.attributes[key] = value
        self.shader:send("u_"..key, value)
        return
    end

    if key == "worldMatrix" then
        self.shader:send("u_world", "column", {value:split()})
        return
    end

    if key == "viewMatrix" then
        self.shader:send("u_view", "column", {value:split()})
        return
    end

    if key == "projectionMatrix" then
        self.shader:send("u_proj", "column", {value:split()})
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material