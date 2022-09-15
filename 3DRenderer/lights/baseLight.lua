local BaseLight = Object:extend()

function BaseLight:new(position, ambient, diffuse, specular, shadowMapSize)
    self.position = position

    self.ambient = ambient
    self.diffuse = diffuse
    self.specular = specular

    self.near = 1
    self.far = 15

    self.enabled = true

    self.shadowmap = lg.newCanvas(shadowMapSize.width, shadowMapSize.height, {format = "depth16", readable = true})
    self.shadowmap:setFilter("nearest", "nearest")
    self.shadowmap:setWrap("clamp")
end

local currCanvas = nil
local currCullMode = nil
local currBlendMode = nil
local currAlphaBlendMode = nil
local currShader = nil
function BaseLight:beginLighting(shader, viewProj, mapFace)
    currCanvas = lg.getCanvas()
    currCullMode = lg.getMeshCullMode()
    currBlendMode, currAlphaBlendMode = lg.getBlendMode()
    currShader = lg.getShader()

    lg.setCanvas {depthstencil = {self.shadowmap, face = mapFace or 1}}
    lg.clear()
    lg.setDepthMode("lequal", true)
    lg.setMeshCullMode("none")
    lg.setBlendMode("replace")
    lg.setShader(shader)

    shader:send("u_viewProj", "column", viewProj:toFlatTable())
end

function BaseLight:endLighting()
    lg.setCanvas(currCanvas)
    lg.setMeshCullMode(currCullMode)
    lg.setBlendMode(currBlendMode, currAlphaBlendMode)
    lg.setShader(currShader)
end

return BaseLight