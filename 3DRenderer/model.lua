local Parseobj = require "engine.contents.objparser"
local Mesh = require "engine.3DRenderer.mesh"
local Meshpart = require "engine.3DRenderer.meshpart"
local Material = require "engine.3DRenderer.material"
local Model = Object:extend()

function Model:new(file)
    self.meshes = {}

    local model = Parseobj(file)

    for k, mesh in pairs(model.objects) do
        local parts = {}

        for i, part in ipairs(mesh) do
            local mat = Material(part.material)
            parts[i] = Meshpart(part.vertices, mat)
        end

        self.meshes[k] = Mesh(parts)
    end
end

return Model