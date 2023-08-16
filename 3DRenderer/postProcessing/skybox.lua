local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

local cubeVertexFormat = {
    {"VertexPosition", "float", 3}
}

local cubeVertices = {
    {-1.0,  1.0, -1.0},
    {-1.0, -1.0, -1.0},
    { 1.0, -1.0, -1.0},
    { 1.0, -1.0, -1.0},
    { 1.0,  1.0, -1.0},
    {-1.0,  1.0, -1.0},

    {-1.0, -1.0,  1.0},
    {-1.0, -1.0, -1.0},
    {-1.0,  1.0, -1.0},
    {-1.0,  1.0, -1.0},
    {-1.0,  1.0,  1.0},
    {-1.0, -1.0,  1.0},

    { 1.0, -1.0, -1.0},
    { 1.0, -1.0,  1.0},
    { 1.0,  1.0,  1.0},
    { 1.0,  1.0,  1.0},
    { 1.0,  1.0, -1.0},
    { 1.0, -1.0, -1.0},

    {-1.0, -1.0,  1.0},
    {-1.0,  1.0,  1.0},
    { 1.0,  1.0,  1.0},
    { 1.0,  1.0,  1.0},
    { 1.0, -1.0,  1.0},
    {-1.0, -1.0,  1.0},

    {-1.0,  1.0, -1.0},
    { 1.0,  1.0, -1.0},
    { 1.0,  1.0,  1.0},
    { 1.0,  1.0,  1.0},
    {-1.0,  1.0,  1.0},
    {-1.0,  1.0, -1.0},

    {-1.0, -1.0, -1.0},
    {-1.0, -1.0,  1.0},
    { 1.0, -1.0, -1.0},
    { 1.0, -1.0, -1.0},
    {-1.0, -1.0,  1.0},
    { 1.0, -1.0,  1.0}
}

local skyboxShader = lg.newShader("engine/shaders/3D/skybox.glsl")
local cube = lg.newMesh(cubeVertexFormat, cubeVertices, "triangles", "static")


--- @class Skybox: BasePostProcessingEffect
---
--- @field texture love.Image
---
--- @overload fun(file: string | string[]): Skybox
local Skybox = BaseEffect:extend()

function Skybox:new(file)
    self.texture = lg.newCubeImage(file)
end


function Skybox:applyPostRender(device, canvas, view, projection)
    view = view:clone()
    view.m41, view.m42, view.m43 = 0, 0, 0

    local viewProj = view * projection
    skyboxShader:send("viewProj", "column", viewProj:toFlatTable())
    skyboxShader:send("skyTex", self.texture)

    lg.setCanvas({canvas, depth = true, depthstencil = device.depthCanvas})
    lg.setMeshCullMode("back")
    lg.setDepthMode("lequal", false)
    lg.setShader(skyboxShader)

    lg.draw(cube)

    lg.setShader()
    lg.setMeshCullMode("none")
    lg.setDepthMode()
    lg.setCanvas()

    return canvas
end


return Skybox