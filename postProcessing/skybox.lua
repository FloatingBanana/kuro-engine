local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Matrix     = require "engine.math.matrix"

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

local skyboxShader = Utils.newPreProcessedShader("engine/shaders/3D/skybox.glsl")
local cube = lg.newMesh(cubeVertexFormat, cubeVertices, "triangles", "static")


--- @class Skybox: BasePostProcessingEffect
---
--- @field texture love.Image
---
--- @overload fun(file: string | string[]): Skybox
local Skybox = BaseEffect:extend()

function Skybox:new(file)
    self.texture = lg.newCubeImage(file)
    self.prevViewProj = Matrix.Identity()
end


function Skybox:onPostRender(renderer, canvas, camera)
    local view = camera.viewMatrix:clone()
    view.m41, view.m42, view.m43 = 0, 0, 0

    local viewProj = view * camera.projectionMatrix --[[@as Matrix]]
    skyboxShader:send("u_viewProj", "column", viewProj:toFlatTable())
    skyboxShader:send("u_prevViewProj", "column", self.prevViewProj:toFlatTable())
    skyboxShader:send("u_skyTex", self.texture)

    self.prevViewProj = viewProj

    lg.setCanvas({canvas, renderer.velocityBuffer, depth = true, depthstencil = renderer.depthCanvas})
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