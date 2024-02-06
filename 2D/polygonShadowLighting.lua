local Vector2    = require "engine.math.vector2"
local Inter2d    = require "engine.math.intersection2d"
local Object     = require "engine.3rdparty.classic.classic"
local lg         = love.graphics
local PolyShadow = Object:extend("PolygonShadowLighting")

local shadowShader = lg.newShader [[
attribute float a_distance;
uniform vec2 u_lightpos;

vec4 position(mat4 transform_projection, vec4 vertex_pos) {
    vec4 outPos = vec4(vertex_pos.xy - a_distance * u_lightpos, 0.0, 1.0 - a_distance);
    
    return transform_projection * outPos;
}
]]

local lightShader = lg.newShader [[
uniform vec2 u_lightpos;
uniform float u_radius;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    float dist = distance(screencoords, u_lightpos);
    float attenuation = max(1.0 - dist / u_radius, 0.0);
    color.a = attenuation*attenuation;
    return color;
}
]]

local vformat = {
    {"VertexPosition", "float", 2},
    {"a_distance", "float", 1},
}
local shadowMesh = lg.newMesh(vformat, 4, "strip", "stream")


function PolyShadow:new(size, ambientColor)
    self.occluders = {}
    self.lights = {}
    self.size = size
    self.lightMap = lg.newCanvas(size.width, size.height)
    self.ambientColor = ambientColor
end

function PolyShadow:addOccluder(polygon, cullingOrder)
    local min, max = Vector2(math.huge), Vector2(-math.huge)

    for i=1, #polygon, 2 do
        local p = Vector2(polygon[i], polygon[i+1])

        min = Vector2.Min(min, p)
        max = Vector2.Max(max, p)
    end

    local occluder = {
        poly = polygon,
        culling = cullingOrder,
        boundingMin = min,
        boundingMax = max
    }

    self.occluders[occluder] = true
    return occluder
end

function PolyShadow:addLight(position, radius, color)
    local light = {
        position = position,
        radius = radius,
        color = color,
    }

    self.lights[light] = true
    return light
end

function PolyShadow:removeOccluder(occluder)
    self.occluders[occluder] = nil
end

function PolyShadow:removeLight(light)
    self.lights[light] = nil
end

local occluders, currLight
local function stencilShadow()
    lg.setShader(shadowShader)

    for occluder in pairs(occluders) do
        if Inter2d.AABB_circle(occluder.boundingMin, occluder.boundingMax, currLight.position, currLight.radius) then
            local poly = occluder.poly

            for i=1, #poly, 2 do
                local p1 = Vector2(poly[i], poly[i+1])
                local p2 = i < #poly-1 and Vector2(poly[i+2], poly[i+3]) or Vector2(poly[1], poly[2])

                if (occluder.culling ~= "noCulling") then
                    local normalAngle = math.rad(occluder.culling == "ccw" and 90 or -90)
                    local segNormal = (p2 - p1):rotateBy(normalAngle)
                    local lightDir = (p1 - currLight.position)

                    if Vector2.Dot(segNormal, lightDir) > 0 then
                        goto ignore
                    end
                end

                shadowMesh:setVertices({
                    {p1.x, p1.y, 0},
                    {p1.x, p1.y, 1},

                    {p2.x, p2.y, 0},
                    {p2.x, p2.y, 1},
                })

                lg.draw(shadowMesh)

                ::ignore::
            end
        end
    end

    lg.setShader()
end

function PolyShadow:bakeLightmap()
    occluders, lights = self.occluders, self.lights

    lg.push("all")
    lg.origin()
    lg.setCanvas({self.lightMap, stencil = true})
    lg.clear(self.ambientColor)
    lg.setBlendMode("add")

    for light in pairs(self.lights) do
        currLight = light
        shadowShader:send("u_lightpos", light.position:toFlatTable())
        lg.stencil(stencilShadow, "replace", 1)
        lg.setStencilTest("equal", 0)

        lg.setColor(light.color)
        lg.setShader(lightShader)
        lightShader:send("u_lightpos", light.position:toFlatTable())
        lightShader:send("u_radius", light.radius)

        local pos = light.position - light.radius
        local size = light.radius*2
        lg.rectangle("fill", pos.x, pos.y, size, size)
    end

    lg.pop()
end

function PolyShadow:renderLighting()
    self:bakeLightmap()

    lg.setBlendMode("multiply", "premultiplied")
    lg.setColor(1,1,1,1)

    lg.draw(self.lightMap, 0, 0)

    lg.setBlendMode("alpha", "alphamultiply")
end

return PolyShadow