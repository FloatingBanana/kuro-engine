local Vector2 = require "engine.math.vector2"
local Vector3 = require "engine.math.vector3"
local Lume    = require "engine.3rdparty.lume"
local Object  = require "engine.3rdparty.classic.classic"

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexTangent", "float", 3},
    {"VertexBoneIDs", "float", 4},
    {"VertexWeights", "float", 4}
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
            float boneIds[4];
            float weights[4];
        }
    ]]
end

local defaultBoneIds = {-1, -1, -1, -1}
local defaultWeights = {0, 0, 0, 0}

--- @alias VertexWeightArray table<integer, number>


--- @class MeshPart: Object
--- @field buffer love.Mesh
--- @field material BaseMaterial
--- @field model Model
---
--- @overload fun(part: unknown, model: Model): MeshPart
local Meshpart = Object:extend("MeshPart")


function Meshpart:new(part, model)
    self.buffer = love.graphics.newMesh(vertexFormat, part:num_vertices(), "triangles", "static")
    self.material = model.materials[part:material():name()]
    self.model = model

    self:__loadVertices(part)
end


--- @private
--- @param aiPart unknown
function Meshpart:__loadVertices(aiPart)
    assert(jitEnabled, "Mesh loading requires jit to be enabled")

    -- Vertices
    local vertices = love.data.newByteData(ffi.sizeof("struct vertex") * aiPart:num_vertices())
    local pointer = ffi.cast("struct vertex*", vertices:getFFIPointer())

    for i=1, aiPart:num_vertices() do
        local index = i-1

        pointer[index].position  = Vector3(aiPart:position(i))
        pointer[index].uv        = Vector2(aiPart:texture_coords(1, i))
        pointer[index].normal    = Vector3(aiPart:normal(i))
        pointer[index].tangent   = Vector3(aiPart:tangent(i))
        pointer[index].boneIds   = defaultBoneIds
        pointer[index].weights   = defaultWeights
    end

    for b=1, aiPart:num_bones() do
        local aiBone = aiPart:bone(b)
        local boneInfo = self.model.boneInfos[aiBone:name()]

        for bv, weight in pairs(aiBone:weights() or {}) do
            local boneVert = bv-1

            for i=0, 3 do
                if pointer[boneVert].boneIds[i] == -1 then
                    pointer[boneVert].boneIds[i] = boneInfo.id
                    pointer[boneVert].weights[i] = weight
                    break
                end
            end
        end
    end

    -- Indices
    local indices = {}
    for i=1, aiPart:num_faces() do
        Lume.push(indices, aiPart:face(i):indices())
    end

    self.buffer:setVertices(vertices)
    self.buffer:setVertexMap(indices)
end


function Meshpart:draw()
    self.material:apply()
    love.graphics.draw(self.buffer)
end


return Meshpart