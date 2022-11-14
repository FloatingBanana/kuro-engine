local Vector3 = require "engine.math.vector3"
local Skybox = Object:extend()

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

function Skybox:new(file)
    self.texture = lg.newCubeImage(file)
end

function Skybox:render(view, projection)
    view = view:clone()
    view.m41, view.m42, view.m43 = 0, 0, 0

    local viewProj = view * projection

    skyboxShader:send("viewProj", "column", viewProj:toFlatTable())
    skyboxShader:send("skyTex", self.texture)

    local comparemode, write = lg.getDepthMode()
    local cullmode = lg.getMeshCullMode()

    lg.setDepthMode("always", false)
    lg.setMeshCullMode("none")

    lg.setShader(skyboxShader)
    lg.draw(cube)
    
    lg.setDepthMode(comparemode, write)
    lg.setMeshCullMode(cullmode)
end

return Skybox