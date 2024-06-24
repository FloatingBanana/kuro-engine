local ShaderEffect = require "engine.misc.shaderEffect"
local Vector3 = require "engine.math.vector3"
local Matrix  = require "engine.math.matrix"
local Utils   = require "engine.misc.utils"
local Vector2 = require "engine.math.vector2"

local Cmap = {}

Cmap.cubeStrip = {
    {-1, 1, 1},
    { 1, 1, 1},
    {-1,-1, 1},
    { 1,-1, 1},
    { 1,-1,-1},
    { 1, 1, 1},
    { 1, 1,-1},
    {-1, 1, 1},
    {-1, 1,-1},
    {-1,-1, 1},
    {-1,-1,-1},
    { 1,-1,-1},
    {-1, 1,-1},
    { 1, 1,-1}
}
Cmap.cubeMesh = love.graphics.newMesh({{"VertexPosition", "float", 3}}, Cmap.cubeStrip, "strip", "static")

Cmap.cubeSides = {
    {dir = Vector3( 1, 0, 0), up = Vector3(0,-1, 0), viewMatrix = Matrix()},
    {dir = Vector3(-1, 0, 0), up = Vector3(0,-1, 0), viewMatrix = Matrix()},
    {dir = Vector3( 0, 1, 0), up = Vector3(0, 0, 1), viewMatrix = Matrix()},
    {dir = Vector3( 0,-1, 0), up = Vector3(0, 0,-1), viewMatrix = Matrix()},
    {dir = Vector3( 0, 0, 1), up = Vector3(0,-1, 0), viewMatrix = Matrix()},
    {dir = Vector3( 0, 0,-1), up = Vector3(0,-1, 0), viewMatrix = Matrix()},
}

for i, side in ipairs(Cmap.cubeSides) do
    side.viewMatrix = Matrix.CreateLookAtDirection(Vector3(0), side.dir, side.up)
end


local projectionMatrix = Matrix.CreatePerspectiveFOV(math.pi*0.5, 1, 0.1, 10)

local vertShaderCode = [[
uniform mat4 u_viewProj;
out vec3 v_localPos;

vec4 position(mat4 transformProjection, vec4 position) {
    v_localPos = position.xyz * vec3(1,-1,1);
    
    return u_viewProj * position;
}
]]


local equirectangularMapToCubeMapShader = ShaderEffect(vertShaderCode, [[
#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform sampler2D u_equirectangularMap;
in vec3 v_localPos;

vec4 effect(EFFECTARGS) {
    vec2 uv = EncodeSphericalMap(normalize(v_localPos));
    vec3 pixel = texture(u_equirectangularMap, uv).rgb;

    return vec4(pixel, 1.0);
}
]])
---@param eqMap love.Texture
---@param format love.PixelFormat?
---@return love.Canvas
function Cmap.equirectangularMapToCubeMap(eqMap, format)
    local cubeCanvas = love.graphics.newCanvas(eqMap:getHeight(), eqMap:getHeight(), {type = "cube", format = format or "rg11b10f", mipmaps = "auto"})
    cubeCanvas:setMipmapFilter("linear")

    equirectangularMapToCubeMapShader:use()
    equirectangularMapToCubeMapShader:sendUniform("u_equirectangularMap", eqMap)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace", "alphamultiply")
    love.graphics.setDepthMode()

    for i, dir in ipairs(Cmap.cubeSides) do
        love.graphics.setCanvas {{cubeCanvas, face = i}}

        equirectangularMapToCubeMapShader:sendUniform("u_viewProj", "column", dir.viewMatrix * projectionMatrix)
        love.graphics.draw(Cmap.cubeMesh)
    end

    love.graphics.setCanvas()
    love.graphics.setShader()

    return cubeCanvas
end


return Cmap