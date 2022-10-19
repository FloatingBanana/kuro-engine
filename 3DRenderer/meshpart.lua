local Material = require "engine.3DRenderer.material"
local Vector2  = require "engine.math.vector2"
local Vector3  = require "engine.math.vector3"
local Meshpart = Object:extend()

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
}

local jitEnabled = jit and jit.status()
local ffi = nil
if jitEnabled then
    ffi = require "ffi"

    ffi.cdef [[
        struct vertex {
            vector3 position;
            vector2 uv;
            vector3 normal;
        }
    ]]
end

function Meshpart:new(part)
    local indices = {}

    for i=1, part:num_faces() do
        Lume.push(indices, part:face(i):indices())
    end

    self.mesh = lg.newMesh(vertexFormat, part:num_vertices(), "triangles", "static")
    self.mesh:setVertexMap(indices)

    if jitEnabled then
        -- Faster version using FFI, requires JIT to be enabled
        local data = love.data.newByteData(ffi.sizeof("struct vertex") * part:num_vertices())
        local pointer = ffi.cast("struct vertex*", data:getFFIPointer())

        for i=1, part:num_vertices() do
            local index = i-1

            pointer[index].position = Vector3(part:position(i))
            pointer[index].uv       = Vector2(part:texture_coords(1, i))
            pointer[index].normal   = Vector3(part:normal(i))
        end

        self.mesh:setVertices(data)
    else
        -- Slower alternative if JIT is not enabled
        local vertices = {}

        for i=1, part:num_vertices() do
            local v = {}

            v[1], v[2], v[3] = part:position(i)
            v[4], v[5]       = part:texture_coords(1, i)
            v[6], v[7], v[8] = part:normal(i)

            vertices[i] = v
        end

        self.mesh:setVertices(vertices)
    end

    self.material = Material(part:material())
end

function Meshpart:draw()
    self.material:apply()
    lg.draw(self.mesh)
end

return Meshpart