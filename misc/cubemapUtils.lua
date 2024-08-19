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


local irradianceMapShader = ShaderEffect(vertShaderCode, [[
#pragma language glsl3

uniform samplerCube u_envMap;
in vec3 v_localPos;

vec4 effect(EFFECTARGS) {
    vec3 normal = normalize(v_localPos);
    vec3 irradiance = vec3(0.0);

    vec3 right = normalize(cross(vec3(0.0,1.0,0.0), normal));
    vec3 up = normalize(cross(normal, right));

    float sampleDelta = 0.025/2.0;
    float nrSamples = 0.0;
    
    for (float phi = 0.0; phi < TAU; phi += sampleDelta) {
        for(float theta = 0.0; theta < HALF_PI; theta += sampleDelta) {
            vec3 tangentSample = vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal;

            irradiance += texture(u_envMap, sampleVec).rgb * cos(theta) * sin(theta);
            nrSamples++;
        }
    }

    irradiance = PI * irradiance * (1.0 / nrSamples);

    return vec4(irradiance, 1.0);
}
]])


local environmentRadianceShader = ShaderEffect(vertShaderCode, [[
#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_IBLCalculation.glsl"
#pragma include "engine/shaders/3D/misc/incl_PBRLighting.glsl"

in vec3 v_localPos;
uniform samplerCube u_envMap;
uniform float u_roughness;

const uint SAMPLE_COUNT = 4096u;

vec4 effect(EFFECTARGS) {
    vec3 N = normalize(v_localPos);
    vec3 R = N;
    vec3 V = N;

    vec3 prefilteredColor = vec3(0.0);
    float totalWeight = 0.0;
    
    for (uint i = 0u; i < SAMPLE_COUNT; ++i) {
        vec2 Xi = Hammersley(i, SAMPLE_COUNT);
        vec3 H = ImportanceSampleGGX(Xi, N, u_roughness);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(dot(N, L), 0.0);
        if (NdotL > 0.0) {
            float HdotV = max(dot(H, V), 0.0);
            float NdotH = max(dot(N, H), 0.0);
            float D = DistributionGGX(NdotH, u_roughness);
            float pdf = (D * NdotH / (4.0 * HdotV)) + 0.0001;

            float resolution = textureSize(u_envMap, 0).x;
            float saTexel = 4.0 * PI / (6.0 * resolution * resolution);
            float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);
            float mipLevel = (u_roughness == 0.0) ? 0.0 : 0.5 * log2(saSample / saTexel);

            prefilteredColor += textureLod(u_envMap, L, mipLevel).rgb * NdotL;
            totalWeight += NdotL;
        }
    }
    
    return vec4(prefilteredColor / totalWeight, 1.0);
}
]])

local calculateBRDF_LUTShader = ShaderEffect [[
#pragma language glsl3
#pragma include "engine/shaders/3D/misc/incl_IBLCalculation.glsl"

const uint SAMPLE_COUNT = 1024u;

vec2 integrateBRDF(float NdotV, float roughness) {
    vec3 V;
    V.x = sqrt(1.0 - NdotV*NdotV);
    V.y = 0.0;
    V.z = NdotV;

    float A = 0.0;
    float B = 0.0;

    vec3 N = vec3(0.0, 0.0, 1.0);

    for (uint i = 0u; i < SAMPLE_COUNT; ++i) {
        vec2 Xi = Hammersley(i, SAMPLE_COUNT);
        vec3 H = ImportanceSampleGGX(Xi, N, roughness);
        vec3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(L.z, 0.0);
        float NdotH = max(H.z, 0.0);
        float VdotH = max(dot(V, H), 0.0);

        if (NdotL > 0.0) {
            float G = GeometrySmith_IBL(dot(N, V), dot(N, L), roughness);
            float G_Vis = (G * VdotH) / (NdotH * NdotV);
            float Fc = pow(1.0 - VdotH, 5.0);

            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }

    A /= float(SAMPLE_COUNT);
    B /= float(SAMPLE_COUNT);

    return vec2(A, B);
}

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
---@return love.Canvas
function Cmap.getIrradianceMap(envMap)
    local irrMap = love.graphics.newCanvas(envMap:getWidth()/4, envMap:getHeight()/4, {type = "cube", format = "rg11b10f"})

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
---@return love.Canvas
function Cmap.environmentRadianceMap(envMap)
    local radianceMap = love.graphics.newCanvas(128, 128, {type = "cube", mipmaps = "manual"})
    radianceMap:setMipmapFilter("linear")
    radianceMap:generateMipmaps()

    environmentRadianceShader:use()
    environmentRadianceShader:sendUniform("u_envMap", envMap)
    love.graphics.setMeshCullMode("front")
    love.graphics.setBlendMode("replace", "alphamultiply")
    love.graphics.setDepthMode()

    local maxMipLevel = 5
    for mip = 0, maxMipLevel-1 do
        local mipSize = 128 * (0.5 ^ mip)
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