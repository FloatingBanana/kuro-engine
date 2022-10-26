local Material = Object:extend()

local textures = {}

local function getTexture(path)
    if not textures[path] then
        textures[path] = lg.newImage("assets/models/"..path)
    end
    return textures[path]
end

function Material:new(mat)
    rawset(self, "__attrs", {
        diffuseColor = {1,1,1},
        specularColor = {1,1,1},
        shininess = 32,
        diffuseTexture = 0,
        normalMap = 0,
    })

    self.shader = lg.newShader(
        "engine/shaders/3D/forwardRendering/forwardRendering.vert",
        "engine/shaders/3D/forwardRendering/forwardRendering.frag"
    )

    local diffuseTexPath = mat:texture_path("diffuse", 1)
    if diffuseTexPath then
        self.diffuseTexture = getTexture(diffuseTexPath)
    end

    local normalTexPath = mat:texture_path("normals", 1)
    if normalTexPath then
        self.normalMap = getTexture(normalTexPath)
    end

    -- self.diffuseColor = {1,1,1,1}
    self.specularColor = {1,1,1,1}
    self.shininess = mat:shininess()
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
        --- @cast value Matrix
        self.shader:send("u_world", "column", value:toFlatTable())
        return
    end

    if key == "viewProjectionMatrix" then
        --- @cast value Matrix
        self.shader:send("u_viewProj", "column", value:toFlatTable())
        return
    end

    if key == "viewPosition" then
        --- @cast value Vector3
        self.shader:send("u_viewPosition", value:toFlatTable())
        return
    end

    rawset(self, key, value)
end

function Material:apply()
    lg.setShader(self.shader)
end

return Material