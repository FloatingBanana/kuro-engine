local Meshpart = Object:extend()

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
}

function Meshpart:new(vertices, material)
    self.mesh = lg.newMesh(vertexFormat, vertices, "triangles", "static")
    self.material = material
end

function Meshpart:draw()
    self.material:apply()
    lg.draw(self.mesh)
end

return Meshpart