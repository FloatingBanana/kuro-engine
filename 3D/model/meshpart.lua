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

--- @alias VertexWeightArray table<integer, number>


--- @class MeshPart: Object
--- @field buffer love.Mesh
--- @field material BaseMaterial
--- @field model Model
---
--- @overload fun(part: unknown, model: Model): MeshPart
local Meshpart = Object:extend("MeshPart")


function Meshpart:new(meshPartData, model)
    self.buffer = love.graphics.newMesh(vertexFormat, #meshPartData.verts, "triangles", "static")
    self.material = model.materials[meshPartData.material]
    self.model = model

    self:__loadVertices(meshPartData)
end


--- @private
--- @param meshPartData table
function Meshpart:__loadVertices(meshPartData)
    assert(jitEnabled, "Mesh loading requires jit to be enabled")

    -- Vertices
    local vertices = love.data.newByteData(ffi.sizeof("struct vertex") * #meshPartData.verts)
    local pointer = ffi.cast("struct vertex*", vertices:getFFIPointer())

    for i, vert in ipairs(meshPartData.verts) do
        local index = i-1

        pointer[index].position  = vert.position
        pointer[index].uv        = Vector2(vert.uv.x, vert.uv.y)
        pointer[index].normal    = vert.normal
        pointer[index].tangent   = vert.tangent
        pointer[index].boneIds   = vert.boneIds
        pointer[index].weights   = vert.weights
    end

    self.buffer:setVertices(vertices)
    self.buffer:setVertexMap(meshPartData.indices)
end


function Meshpart:draw()
    self.material:apply()
    love.graphics.draw(self.buffer)
end


return Meshpart