local Material = Object:extend()

function Material:new(attributes)
    rawset(self, "attributes", attributes)

    self.shader = lg.newShader("engine/shaders/3D/forwardRendering/forwardRendering.vert", "engine/shaders/3D/forwardRendering/forwardRendering.frag")

    for key, value in pairs(attributes) do
        if key == "ambientTexture" or key == "diffuseTexture" or key == "specularTexture" then
            self[key] = lg.newImage(value.texture)

        elseif self.shader:hasUniform("u_"..key) then
            self.shader:send("u_"..key, value)
        end
    end
end

function Material:__index(key)
    if rawget(self, "attributes") and self.attributes[key] then
        return self.attributes[key]
    end

    return Material[key]
end

function Material:__newindex(key, value)
    if self.attributes[key] then
        self.attributes[key] = value
        self.shader:send("u_"..key, value)
        return
    end

    if key == "worldMatrix" then
        self.shader:send("u_world", "column", value:toFlatTable())
        self.shader:send("u_invTranspWorld", "column", value.inverse:transpose():to3x3():toFlatTable())
        return
    end

    if key == "viewMatrix" then
        self.shader:send("u_view", "column", value:toFlatTable())
        return
    end

    if key == "projectionMatrix" then
        self.shader:send("u_proj", "column", value:toFlatTable())
        return
    end

    if key == "viewPosition" then
        self.shader:send("u_viewPosition", value:toFlatTable())
        return
    end

    if key == "shininess" then
        self.shader:send("u_shininess", value)
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material