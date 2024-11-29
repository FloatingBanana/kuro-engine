local ShaderEffect = require "engine.misc.shaderEffect"
local Vector3      = require "engine.math.vector3"
local Matrix4      = require "engine.math.matrix4"
local Utils        = require "engine.misc.utils"
local Vector2      = require "engine.math.vector2"

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
    {dir = Vector3( 1, 0, 0), up = Vector3(0,-1, 0), viewMatrix = Matrix4()},
    {dir = Vector3(-1, 0, 0), up = Vector3(0,-1, 0), viewMatrix = Matrix4()},
    {dir = Vector3( 0, 1, 0), up = Vector3(0, 0, 1), viewMatrix = Matrix4()},
    {dir = Vector3( 0,-1, 0), up = Vector3(0, 0,-1), viewMatrix = Matrix4()},
    {dir = Vector3( 0, 0, 1), up = Vector3(0,-1, 0), viewMatrix = Matrix4()},
    {dir = Vector3( 0, 0,-1), up = Vector3(0,-1, 0), viewMatrix = Matrix4()},
}

for i, side in ipairs(Cmap.cubeSides) do
    side.viewMatrix = Matrix4.CreateLookAtDirection(Vector3(0), side.dir, side.up)
end


local projectionMatrix = Matrix4.CreatePerspectiveFOV(math.pi*0.5, 1, 0.1, 10)

local vertShaderCode = [[
uniform mat4 u_viewProj;
out vec3 v_localPos;

vec4 position(mat4 transformProjection, vec4 position) {
    v_localPos = position.xyz;

#ifdef INVERT_Y
    v_localPos.y *= -1.0;
#endif
    
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
]], {"INVERT_Y"})


local irradianceMapShader = ShaderEffect(vertShaderCode, [[
#define IRRADIANCE_SAMPLE_DELTA 0.025

#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_IBLCalculation.glsl"

uniform samplerCube u_envMap;
in vec3 v_localPos;

vec4 effect(EFFECTARGS) {
    return vec4(CalculateIrradiance(u_envMap, normalize(v_localPos)), 1.0);
}
]])


local environmentRadianceShader = ShaderEffect(vertShaderCode, [[
#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_IBLCalculation.glsl"

in vec3 v_localPos;
uniform samplerCube u_envMap;
uniform float u_roughness;

vec4 effect(EFFECTARGS) {
    return vec4(CalculateEnvironmentRadiance(u_envMap, normalize(v_localPos), u_roughness), 1.0);
}
]])

local calculateBRDF_LUTShader = ShaderEffect [[
#define BRDF_SAMPLE_COUNT 1024

#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_IBLCalculation.glsl"

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec2 brdf = integrateBRDF(texcoords.x, 1.0 - texcoords.y);
    return vec4(brdf, 1.0, 1.0);
}
]]

local cubeMapToEquirectangularMapShader = ShaderEffect [[
#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform samplerCube u_cubeMap;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    return texture(u_cubeMap, DecodeSphericalMap(vec2(texcoords.x, 1.0 - texcoords.y)));
}
]]


---@param eqMap love.Texture
---@param format love.PixelFormat?
---@return love.Canvas
function Cmap.equirectangularMapToCubeMap(eqMap, format)
    local cubeCanvas = love.graphics.newCanvas(eqMap:getHeight(), eqMap:getHeight(), {type = "cube", format = format or eqMap:getFormat(), mipmaps = "auto"})
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




---@param cubeMap love.Texture
---@param format love.PixelFormat?
---@return love.Canvas
function Cmap.cubeMapToEquirectangularMap(cubeMap, format)
    local size = Vector2(cubeMap:getWidth() * 2, cubeMap:getHeight())
    local eqMap = love.graphics.newCanvas(size.x, size.y, {format = format or cubeMap:getFormat()})
    local square = Utils.newSquareMesh(size)

    love.graphics.setCanvas(eqMap)
    cubeMapToEquirectangularMapShader:use()
    cubeMapToEquirectangularMapShader:sendUniform("u_cubeMap", cubeMap)
    love.graphics.draw(square)
    love.graphics.setCanvas()
    love.graphics.setShader()

    return eqMap
end




---@param envMap love.Texture
---@param size Vector2
---@return love.Canvas
function Cmap.getIrradianceMap(envMap, size)
    local irrMap = love.graphics.newCanvas(size.width, size.height, {type = "cube", format = "rg11b10f"})

    irradianceMapShader:use()
    irradianceMapShader:sendUniform("u_envMap", envMap)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace", "alphamultiply")
    love.graphics.setDepthMode()

    for i, dir in ipairs(Cmap.cubeSides) do
        love.graphics.setCanvas {{irrMap, face = i}}

        irradianceMapShader:sendUniform("u_viewProj", "column", dir.viewMatrix * projectionMatrix)
        love.graphics.draw(Cmap.cubeMesh)
    end

    love.graphics.setCanvas()
    love.graphics.setShader()

    return irrMap
end



---@param envMap love.Texture
---@param size Vector2
---@param sampleCount integer?
---@return love.Canvas
function Cmap.environmentRadianceMap(envMap, size, sampleCount)
    local radianceMap = love.graphics.newCanvas(size.width, size.height, {type = "cube", mipmaps = "manual", format = "rg11b10f"})
    radianceMap:setMipmapFilter("linear")
    radianceMap:generateMipmaps()

    environmentRadianceShader:define("ENVIRONMENT_RADIANCE_SAMPLE_COUNT", sampleCount or 1024)
    environmentRadianceShader:use()
    environmentRadianceShader:sendUniform("u_envMap", envMap)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace", "alphamultiply")
    love.graphics.setDepthMode()

    local maxMipLevel = 5
    for mip = 0, maxMipLevel-1 do
        local roughness = mip / (maxMipLevel - 1)

        for i, dir in ipairs(Cmap.cubeSides) do
            love.graphics.setCanvas {{radianceMap, face = i, mipmap = mip+1}}

            environmentRadianceShader:sendUniform("u_roughness", roughness)
            environmentRadianceShader:sendUniform("u_viewProj", "column", dir.viewMatrix * projectionMatrix)
            love.graphics.draw(Cmap.cubeMesh)
        end
    end

    love.graphics.setCanvas()
    love.graphics.setShader()

    return radianceMap
end



---@return love.Canvas
function Cmap.getBRDF_LUT()
    local lutTexture = love.graphics.newCanvas(512, 512, {format = "rg16"})
    local dummySquare = Utils.newSquareMesh(Vector2(512))

    calculateBRDF_LUTShader:use()
    love.graphics.setCanvas(lutTexture)
    love.graphics.draw(dummySquare)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return lutTexture
end



return Cmap