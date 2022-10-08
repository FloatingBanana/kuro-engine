local Material = require "engine.3DRenderer.material"
local Meshpart = Object:extend()

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
}

function Meshpart:new(part)
    local vertices = {}
    local indices = {}

    for i=1, part:num_vertices() do
        local v = {}

        v[1], v[2], v[3] = part:position(i)
        v[4], v[5]       = 0, 0--part:texture_coords(1, i)
        v[6], v[7], v[8] = part:normal(i)

        vertices[i] = v
    end

    for i=1, part:num_faces() do
        Lume.push(indices, part:face(i):indices())
    end

    self.mesh = lg.newMesh(vertexFormat, vertices, "triangles", "static")
    self.mesh:setVertexMap(indices)


    self.material = Material(part:material())
end

function Meshpart:draw()
    self.material:apply()
    lg.draw(self.mesh)
end

return Meshpart