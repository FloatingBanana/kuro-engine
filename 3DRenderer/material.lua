local Material = Object:extend()

function Material:new(mat)
    rawset(self, "__attrs", {
        diffuseColor = {1,1,1},
        specularColor = {1,1,1},
        shininess = 32
    })

    self.shader = lg.newShader("engine/shaders/3D/forwardRendering/forwardRendering.vert", "engine/shaders/3D/forwardRendering/forwardRendering.frag")

    self.shader:send("u_diffuseColor", {mat:color_diffuse()})
    self.shader:send("u_specularColor", {mat:color_specular()})
    self.shader:send("u_shininess", mat:shininess())
end

function Material:__index(key)
    if rawget(self, "__attrs") and self.__attrs[key] then
        return self.__attrs[key]
    end

    return Material[key]
end

function Material:__newindex(key, value)
    if self.__attrs[key] then
        self.__attrs[key] = value
        self.shader:send("u_"..key, value)
    end

    if key == "worldMatrix" then
        self.shader:send("u_world", "column", value:toFlatTable())
        self.shader:send("u_invTranspWorld", "column", value.inverse:transpose():to3x3():toFlatTable())
        return
    end

    if key == "viewProjectionMatrix" then
        self.shader:send("u_viewProj", "column", value:toFlatTable())
        return
    end

    if key == "viewPosition" then
        self.shader:send("u_viewPosition", value:toFlatTable())
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material