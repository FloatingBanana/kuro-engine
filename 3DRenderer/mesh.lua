--- @class Mesh: Object
---
--- @field parts MeshPart[]
--- @field transformation Matrix
--- @field materials Material[]
---
--- @overload fun(meshparts: MeshPart[], transformation: Matrix)
local Mesh = Object:extend()


function Mesh:new(meshparts, transformation)
    self.parts = meshparts
    self.transformation = transformation
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