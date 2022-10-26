local Assimp = require "moonassimp"
local Mesh = require "engine.3DRenderer.mesh"
local Meshpart = require "engine.3DRenderer.meshpart"
local Model = Object:extend()

function Model:new(file)
    self.meshes = {}

    local data = lfs.read("string", file)
    local model, err = Assimp.import_file_from_memory(data, "triangulate", "sort by p type", "optimize meshes", "flip uvs", "calc tangent space")

    assert(model, err)

    local root = model:root_node()

    self:__loadNode(root, model)
end

function Model:__loadNode(node, model)
    if node:num_meshes() > 0 then
        local parts = {}

        for i, part in pairs(node:meshes()) do
            parts[i] = Meshpart(part)
        end
        
        self.meshes[node:name()] = Mesh(parts)
    end

    for i, child in ipairs(node:children()) do
        self:__loadNode(child, model)
    end
end

return Model