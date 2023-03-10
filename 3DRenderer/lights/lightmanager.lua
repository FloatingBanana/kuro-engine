local DirLight = require "engine.3DRenderer.lights.directionalLight"
local PointLight = require "engine.3DRenderer.lights.pointLight"
local SpotLight = require "engine.3DRenderer.lights.spotLight"
local Lightmng = Object:extend()

local MAX_LIGHTS = 10

local dataList = {
    u_lightType           = {},
    u_lightPosition       = {},
    u_lightDirection      = {},
    u_lightMatrix         = {},
    u_lightColor          = {},
    u_lightVars           = {},
    u_lightEnabled        = {},
    u_lightShadowMap      = {},
    u_lightAmbient        = {},
    u_lightDiffuse        = {},
    u_lightSpecular       = {},
    u_pointLightShadowMap = {}
}

function Lightmng:new()
    self.meshparts = {}
    self.materials = {}
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

function Lightmng:addMaterial(...)
    for i=1, select("#", ...) do
        self.materials[select(i, ...)] = true
    end
end

function Lightmng:removeMaterial(...)
    for i=1, select("#", ...) do
        self.materials[select(i, ...)] = nil
    end
end

function Lightmng:addLights(...)
    for i=1, select("#", ...) do
        Lume.push(self.lights, select(i, ...))
    end
end

function Lightmng:removeLights(...)
    for i=1, select("#", ...) do
        local index = Lume.find(self.lights, select(i, ...))

        if index then
            table.remove(self.lights, index)
        end
    end
end

function Lightmng:applyLighting()
    for i, light in ipairs(self.lights) do
        local lightType =
            light:is(DirLight)   and 0 or
            light:is(SpotLight)  and 1 or
            light:is(PointLight) and 2 or error("invalid light type")

        dataList.u_lightType[i] = lightType
        dataList.u_lightEnabled[i] = light.enabled

        light:setupLightData(self.meshparts, dataList, i)
    end

    for i = #self.lights+1, MAX_LIGHTS do
        dataList.u_lightEnabled[i] = false
    end

    for material in pairs(self.materials) do
        for name, data in pairs(dataList) do
            if name ~= "u_lightColor" and data[1] then
                material.shader:send(name, unpack(data))
            end
        end
    end
end

return Lightmng