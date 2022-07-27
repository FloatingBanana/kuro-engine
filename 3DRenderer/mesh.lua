local Mesh = Object:extend()

function Mesh:new(meshparts)
    self.parts = meshparts
    self.materials = {}

    for i, part in ipairs(meshparts) do
        self.materials[i] = part.material
    end
end

function Mesh:draw()
    for i, part in ipairs(self.parts) do
        part:draw()
    end
end

return Mesh