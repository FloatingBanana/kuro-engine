local Material = Object:extend()

function Material:new(attributes)
    rawset(self, "attributes", attributes)

    self.shader = lg.newShader("engine/3DRenderer/shaders/3drendering.vert", "engine/3DRenderer/shaders/diffuselighting.frag")

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
        self.shader:send("u_world", "column", {value:split()})

        local itm = value.inverse:transpose()
        self.shader:send("u_invTranspWorld", "column", {itm.m11, itm.m12, itm.m13, itm.m21, itm.m22, itm.m23, itm.m31, itm.m32, itm.m33})
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

    if key == "viewPosition" then
        self.shader:send("u_viewPosition", {value:split()})
        return
    end

    if key == "directionalLight" then
        self.shader:send("u_dirLight.direction", {value.direction:split()})
        self.shader:send("u_dirLight.ambient", {value.ambient:split()})
        self.shader:send("u_dirLight.diffuse", {value.diffuse:split()})
        self.shader:send("u_dirLight.specular", {value.specular:split()})
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material