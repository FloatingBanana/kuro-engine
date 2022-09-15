local DirLight = require "engine.3DRenderer.lights.directionalLight"
local PointLight = require "engine.3DRenderer.lights.pointLight"
local SpotLight = require "engine.3DRenderer.lights.spotLight"
local Lightmng = Object:extend()

function Lightmng:new()
    self.meshparts = {}
    self.lights = {}
end

function Lightmng:addMeshParts(worldMatrix, ...)
    for i=1, select("#", ...) do
        self.meshparts[select(i, ...)] = worldMatrix
    end
end

function Lightmng:removeMeshParts(...)
    for i=1, select("#", ...) do
        self.meshparts[select(i, ...)] = nil
    end
end

function Lightmng:setMeshPartMatrix(part, matrix)
    assert(self.meshparts[part], "Mesh part not was not added")

    self.meshparts[part] = matrix
end

function Lightmng:addLights(...)
    for i=1, select("#", ...) do
        self.lights[select(i, ...)] = true
    end
end

function Lightmng:removeLights(...)
    for i=1, select("#", ...) do
        self.lights[select(i, ...)] = nil
    end
end

function Lightmng:applyLighting()
    local dirIndex   = 0
    local pointIndex = 0
    local spotIndex  = 0

    for light in pairs(self.lights) do
        if light:is(DirLight) then
            light:applyLighting(self.meshparts, dirIndex)
            dirIndex = dirIndex + 1
        end

        if light:is(PointLight) then
            light:applyLighting(self.meshparts, pointIndex)
            pointIndex = pointIndex + 1
        end

        if light:is(SpotLight) then
            light:applyLighting(self.meshparts, spotIndex)
            spotIndex = spotIndex + 1
        end
    end
end

return Lightmng