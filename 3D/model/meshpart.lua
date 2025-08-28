local Object  = require "engine.3rdparty.classic.classic"
local ffi     = require "ffi"

local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoords", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexTangent", "float", 3},
    {"VertexBoneIDs", "float", 4},
    {"VertexWeights", "float", 4}
}

ffi.cdef [[
    struct vertex {
        Vector3 position;
        Vector2 uv;
        Vector3 normal;
        Vector3 tangent;
        float boneIds[4];
        float weights[4];
    }
]]

--- @alias VertexWeightArray table<integer, number>


--- @class MeshPart: Object
--- @field buffer love.Mesh
--- @field material BaseMaterial
--- @field aabb BoundingBox
--- @field model Model
---
--- @overload fun(part: unknown, model: Model): MeshPart
local Meshpart = Object:extend("MeshPart")


function Meshpart:new(meshPartData, model)
    self.buffer = love.graphics.newMesh(vertexFormat, #meshPartData.positions, "triangles", "static")
    self.material = model.materials[meshPartData.material]
    self.model = model
    self.aabb = meshPartData.aabb

    self:__loadVertices(meshPartData)
end


--- @private
--- @param meshPartData table
function Meshpart:__loadVertices(meshPartData)
    -- Vertices
    local vertices = love.data.newByteData(ffi.sizeof("struct vertex") * #meshPartData.positions)
    local pointer = ffi.cast("struct vertex*", vertices:getFFIPointer())

    for i=1, #meshPartData.positions do
        local index = i-1

        pointer[index].position  = meshPartData.positions[i]
        pointer[index].uv        = meshPartData.uvs[i]
        pointer[index].normal    = meshPartData.normals[i]
        pointer[index].tangent   = meshPartData.tangents[i]
        pointer[index].boneIds   = meshPartData.boneIds[i]
        pointer[index].weights   = meshPartData.weights[i]
    end

    self.buffer:setVertices(vertices)
    self.buffer:setVertexMap(meshPartData.indices)
end


function Meshpart:draw()
    love.graphics.draw(self.buffer)
end


return Meshpart