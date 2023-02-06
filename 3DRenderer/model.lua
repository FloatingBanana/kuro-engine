local Assimp = require "moonassimp"
local Matrix = require "engine.math.matrix"
local Mesh = require "engine.3DRenderer.mesh"
local Meshpart = require "engine.3DRenderer.meshpart"
local FRMaterial = require "engine.3DRenderer.materials.forwardRenderingMaterial"
local Model = Object:extend()

function Model:new(file, opts)
    self.meshes = {}
    self.materials = {}
    self.opts = opts

    -- Read model data
    local data = lfs.read("string", file)
    local model, err = Assimp.import_file_from_memory(data, "triangulate", "sort by p type", "optimize meshes", "flip uvs", "calc tangent space")

    assert(model, err)

    -- Load materials
    for i=1, model:num_materials() do
        local mat = model:material(i)
        local name = mat:name()
        local matClass = opts.materials[name]

        if not matClass then
            print("Material class for '"..name.."' not defined, using a default one")
            matClass = FRMaterial
        end

        self.materials[name] = matClass(mat)
    end

    -- Start loading from root node
    local root = model:root_node()
    self:__loadNode(root, model, Matrix.identity())
end

function Model:__loadNode(node, model, parentTransform)
    local transform = parentTransform * Matrix(node:transformation()):transpose()

    if node:num_meshes() > 0 then
        local parts = {}

        -- Get mesh parts
        for i, part in pairs(node:meshes()) do
            parts[i] = Meshpart(part, self)
        end

        -- Create mesh
        self.meshes[node:name()] = Mesh(parts, transform)
    end

    -- Load children
    for i, child in ipairs(node:children()) do
        self:__loadNode(child, model, transform)
    end
end

return Model