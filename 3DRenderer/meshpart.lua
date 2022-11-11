local Material = require "engine.3DRenderer.material"
local Vector2  = require "engine.math.vector2"
local Vector3  = require "engine.math.vector3"
local Meshpart = Object:extend()

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexTangent", "float", 3},
    {"VertexBitangent", "float", 3},
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
            vector3 tangent;
            vector3 bitangent;
        }
    ]]
end

function Meshpart:new(part)
    local indices = {}

    self.mesh = lg.newMesh(vertexFormat, part:num_vertices(), "triangles", "static")
    self.material = Material(part:material())
    
    self:__loadVertices(part)
end

function Meshpart:__loadVertices(part)
    local indices = {}
    local vertices = nil

    -- Vertices
    if jitEnabled then
        -- Faster version using FFI, requires JIT to be enabled
        vertices = love.data.newByteData(ffi.sizeof("struct vertex") * part:num_vertices())
        local pointer = ffi.cast("struct vertex*", vertices:getFFIPointer())

        for i=1, part:num_vertices() do
            local index = i-1

            pointer[index].position  = Vector3(part:position(i))
            pointer[index].uv        = Vector2(part:texture_coords(1, i))
            pointer[index].normal    = Vector3(part:normal(i))
            pointer[index].tangent   = Vector3(part:tangent(i))
            pointer[index].bitangent = Vector3(part:bitangent(i))
        end
    else
        -- Slower alternative if JIT is not enabled
        vertices = {}

        for i=1, part:num_vertices() do
            local v = {}

            v[1],  v[2],  v[3]  = part:position(i)
            v[4],  v[5]         = part:texture_coords(1, i)
            v[6],  v[7],  v[8]  = part:normal(i)
            v[9],  v[10], v[11] = part:tangent(i)
            v[12], v[13], v[14] = part:bitangent(i)

            vertices[i] = v
        end
    end

    -- Indices
    for i=1, part:num_faces() do
        Lume.push(indices, part:face(i):indices())
    end

    self.mesh:setVertices(vertices)
    self.mesh:setVertexMap(indices)
end

function Meshpart:draw()
    self.material:apply()
    self.material.shader:send("u_isCanvasEnabled", lg.getCanvas() ~= nil)
    lg.draw(self.mesh)
end

return Meshpart