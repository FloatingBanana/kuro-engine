local Vector2 = require "engine.math.vector2"
local Utils = require "engine.misc.utils"

local Dbg = {}

local modstates = {}
function Dbg.wasFileModified(file)
    local currModtime = love.filesystem.getInfo(file, "file").modtime
    local lastModtime = modstates[file]

    modstates[file] = currModtime
    return lastModtime and currModtime ~= lastModtime
end

function Dbg.hotswap(file)
    package.loaded[file] = nil
    return require(file)
end

function Dbg.hotswapWhenModified(file)
    local fullFile = file:gsub("%.", "/")..".lua"

    if Dbg.wasFileModified(fullFile) then
        return Dbg.hotswap(file)
    end
end


local cubeshader = love.graphics.newShader [[
uniform samplerCube cubeImg;
uniform vec3 faceDir;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 dir;

    if (faceDir.x != 0)
        dir = vec3(faceDir.x, texcoords.x, texcoords.y);
    if (faceDir.y != 0)
        dir = vec3(texcoords.x, faceDir.y, texcoords.y);
    if (faceDir.z != 0)
        dir = vec3(texcoords.x, texcoords.y, faceDir.z);

    return Texel(cubeImg, dir) * color;
}
]]
function Dbg.drawCubemapFace(cubemap, face, ...)
    local square = Utils.newSquareMesh(Vector2(cubemap:getDimensions()))
    
    cubeshader:send("cubeImg", cubemap)
    cubeshader:send("faceDir", face:toFlatTable())
    love.graphics.setShader(cubeshader)
    love.graphics.draw(square, ...)
    love.graphics.setShader()
end

return Dbg