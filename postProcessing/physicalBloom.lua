local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local upsampleShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/upsample.frag")
local downsampleShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/downsample.frag")

local interpolateShader = Utils.newPreProcessedShader [[
#pragma language glsl3
#pragma include "engine/shaders/postprocessing/upsample.frag"

uniform sampler2D u_bloomTex;
uniform float u_filterRadius;
uniform float u_bloomAmount;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 pixel = texture(tex, texcoords).rgb;
    vec3 bloomPixel = Upsample(u_bloomTex, texcoords, u_filterRadius).rgb;

    vec3 result = mix(pixel, bloomPixel, u_bloomAmount);
    return vec4(result, 1.0);
}
]]

local MIPMAP_COUNT = 5

--- @class PhysicalBloom: BasePostProcessingEffect
---
--- @field public filterRadius number
--- @field public bloomAmount number
--- @field private blurCanvas love.Canvas
--- @field private mipmaps love.Canvas[]
---
--- @overload fun(screenSize: Vector2): PhysicalBloom
local Bloom = BaseEffect:extend("PhysicalBloom")


function Bloom:new(screenSize)
    self.filterRadius = 0.005
    self.bloomAmount = 0.04
    self.blurCanvas = lg.newCanvas(screenSize.x, screenSize.y, {format = "rg11b10f"})
    self.mipmaps = self:generateMipmaps(MIPMAP_COUNT)

    self.blurCanvas:setFilter("linear", "linear")
    self.blurCanvas:setWrap("clamp", "clamp")
end


function Bloom:onPostRender(renderer, camera, canvas)
    local mips = self.mipmaps

    lg.setShader(downsampleShader)
    lg.setBlendMode("replace", "premultiplied")
    for i=1, #mips do
        lg.setCanvas(mips[i])
        lg.draw(i==1 and canvas or mips[i-1], 0, 0, 0, .5, .5)
    end

    lg.setShader(upsampleShader)
    lg.setBlendMode("add", "premultiplied")
    upsampleShader:send("u_filterRadius", self.filterRadius)
    for i = #mips, 2, -1 do
        lg.setCanvas(mips[i-1])
        lg.draw(mips[i], 0, 0, 0, 2, 2)
    end

    lg.setBlendMode("alpha", "alphamultiply")

    lg.setCanvas(self.blurCanvas)
    lg.setShader(interpolateShader)
    interpolateShader:send("u_filterRadius", self.filterRadius)
    interpolateShader:send("u_bloomAmount", self.bloomAmount)
    interpolateShader:send("u_bloomTex", mips[1])

    lg.draw(canvas)

    return self.blurCanvas
end

function Bloom:generateMipmaps(count)
    local mips = {}

    for i = 1, count do
        local w = self.blurCanvas:getWidth()  * (0.5 ^ i)
        local h = self.blurCanvas:getHeight() * (0.5 ^ i)

        mips[i] = lg.newCanvas(w, h, {format = "rg11b10f"})
        mips[i]:setFilter("linear", "linear")
        mips[i]:setWrap("clamp", "clamp")
    end

    return mips
end


return Bloom