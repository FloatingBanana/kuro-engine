local Vector2    = require "engine.math.vector2"
local Inter2d    = require "engine.math.intersection2d"
local Object     = require "engine.3rdparty.classic.classic"
local lg         = love.graphics

---@alias Light2D {pos: Vector2, radius: number, color: number[], shadowMap: love.Canvas}
---@alias Occluder2D {pos: Vector2, poly: number[], boundingMin: Vector2, boundingMax: Vector2, culling: "cw"|"ccw"}

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
uniform sampler2D u_shadowMap;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    float dist = distance(screencoords, u_lightpos);
    float attenuation = max(1.0 - dist / u_radius, 0.0);
    float visibility = Texel(u_shadowMap, texcoords).r;
    
    return Texel(texture, texcoords) * color * (attenuation * attenuation) * visibility;
}
]]


local vformat = {
    {"VertexPosition", "float", 2},
    {"a_distance", "float", 1},
}
local shadowMesh = lg.newMesh(vformat, 4, "strip", "stream")



local vdata = {
    {0, 0, 0},
    {0, 0, 1},
    {0, 0, 0},
    {0, 0, 1},
}
local function updateVertices(v1, v2)
    vdata[1][1], vdata[1][2] = v1.x, v1.y
    vdata[2][1], vdata[2][2] = v1.x, v1.y

    vdata[3][1], vdata[3][2] = v2.x, v2.y
    vdata[4][1], vdata[4][2] = v2.x, v2.y

    shadowMesh:setVertices(vdata)
end


---@class LightRenderer2D : Object
---
---@field public ambientColor number[]
---@field public lightMap love.Canvas
---@field private size Vector2
---@field private lights table<Light2D, boolean>
---@field private occluders table<Occluder2D, boolean>
---
---@overload fun(size: Vector2, ambientColor: number[]): LightRenderer2D
local Renderer2d = Object:extend("LightRenderer2D")

function Renderer2d:new(size, ambientColor)
    self.occluders = {}
    self.lights = {}
    self.size = size
    self.lightMap = lg.newCanvas(size.width, size.height, {format = "rgba16f"})
    self.ambientColor = ambientColor
end


function Renderer2d:addOccluder(pos, polygon, cullingOrder)
    local min, max = Vector2(math.huge), Vector2(-math.huge)

    for i, p in ipairs(polygon) do
        min = Vector2.Min(min, p)
        max = Vector2.Max(max, p)
    end

    local occluder = {
        pos = pos,
        poly = polygon,
        culling = cullingOrder,
        boundingMin = min,
        boundingMax = max
    }

    self.occluders[occluder] = true
    return occluder
end

function Renderer2d:addRectangleOccluder(pos, size)
    local poly = {
        Vector2(0,0),
        Vector2(size.width,0),
        Vector2(size.width,size.height),
        Vector2(0,size.height),
    }
    return self:addOccluder(pos, poly, "cw")
end

function Renderer2d:addCircleOccluder(pos, radius, segments)
    local poly = {}

    for i=1, segments do
        local angle = (math.pi*2) / segments * i

        poly[i] = Vector2(
            math.sin(angle) * radius,
            math.cos(angle) * radius
        )
    end

    return self:addOccluder(pos, poly, "ccw")
end


function Renderer2d:addLight(position, radius, color)
    local light = {
        pos = position,
        radius = radius,
        color = color,
        shadowMap = lg.newCanvas(self.size.x, self.size.y, {format = "r8"})
    }

    self.lights[light] = true
    return light
end


function Renderer2d:removeOccluder(occluder)
    self.occluders[occluder] = nil
end


function Renderer2d:removeLight(light)
    self.lights[light] = nil
end

function Renderer2d:_updateShadows()
    lg.setShader(shadowShader)
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setColor(0,0,0,1)

    for light in pairs(self.lights) do
        lg.setCanvas(light.shadowMap)
        lg.clear(1,1,1,1)
        shadowShader:send("u_lightpos", light.pos:toFlatTable())

        for occluder in pairs(self.occluders) do
            -- if Inter2d.AABB_circle(occluder.boundingMin + occluder.pos.x, occluder.boundingMax + occluder.pos.y, light.pos, light.radius) then
                local poly = occluder.poly
    
                for i=1, #poly do
                    local p1 = occluder.pos + poly[i]
                    local p2 = occluder.pos + (i < #poly and poly[i+1] or poly[1])
    
                    if occluder.culling ~= "noCulling" then
                        local normalAngle = math.rad(occluder.culling == "ccw" and 90 or -90)
                        local segNormal = (p2 - p1):rotateBy(normalAngle)
                        local lightDir = (p1 - light.pos)
    
                        if Vector2.Dot(segNormal, lightDir) > 0 then
                            goto ignore
                        end
                    end

                    updateVertices(p1, p2)
    
                    lg.draw(shadowMesh)
    
                    ::ignore::
                end
            -- end
        end
    end
end

function Renderer2d:render(canvas)
    self:_updateShadows()

    lg.setCanvas({self.lightMap, stencil = true})
    lg.setBlendMode("add", "premultiplied")
    lg.clear(0,0,0,1)
    
    -- Ambient pass
    lg.setShader()
    lg.setColor(self.ambientColor)
    lg.draw(canvas)

    for light in pairs(self.lights) do
        lg.setShader(lightShader)
        lightShader:send("u_lightpos", light.pos:toFlatTable())
        lightShader:send("u_radius", light.radius)
        lightShader:send("u_shadowMap", light.shadowMap)

        lg.setColor(light.color)
        lg.draw(canvas)
    end

    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setColor(1,1,1,1)
    lg.setCanvas()
end

return Renderer2d