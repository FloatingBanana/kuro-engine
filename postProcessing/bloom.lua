local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local brightFilterShader = [[
#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

uniform float u_treshold;

vec4 effect(vec4 color, sampler2D tex, vec2 texcoords, vec2 screencoords) {
    vec3 pixel = texture(tex, texcoords).rgb;
    float lum = Luminance(pixel);
    float shine = max(0.0, lum - u_treshold);
    
    return vec4(pixel * sign(shine), 1.0);
}
]]


--- @class Bloom: BasePostProcessingEffect
---
--- @field public strenght integer
--- @field public luminanceTreshold number
--- @field private blurShader love.Shader
--- @field private brightFilterShader love.Shader
--- @field private bloomCanvas love.Canvas
--- @field private blurCanvases love.Canvas[]
---
--- @overload fun(screenSize: Vector2, strenght: integer, luminanceTreshold: number): Bloom
local Bloom = BaseEffect:extend("Bloom")


function Bloom:new(screenSize, strenght, luminanceTreshold)
    self.strenght = strenght
    self.luminanceTreshold = luminanceTreshold
    self.blurShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/gaussianBlurOptimized.frag")
    self.brightFilterShader = Utils.newPreProcessedShader(brightFilterShader)

    self.bloomCanvas = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rg11b10f"})
    self.blurCanvases = {
        [0] = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rg11b10f"}),
        [1] = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rg11b10f"})
    }

    self.bloomCanvas:setFilter("linear", "linear")
    self.blurCanvases[0]:setFilter("linear", "linear")
    self.blurCanvases[1]:setFilter("linear", "linear")

    self:setLuminanceTreshold(luminanceTreshold)
end


function Bloom:onPostRender(renderer, canvas, camera)
    -- Get luminous pixels
    lg.setCanvas(self.bloomCanvas)
    lg.setShader(self.brightFilterShader)
    lg.draw(canvas, 0,0,0,.5,.5)

    lg.setShader(self.blurShader)
    lg.setBlendMode("alpha", "premultiplied")

    for i=1, self.strenght*2 do
        local index = i % 2
        local blurDir = {index, 1-index}

        self.blurShader:send("direction", blurDir)
        lg.setCanvas(self.blurCanvases[index])

        if i==1 then
            lg.draw(self.bloomCanvas)
        else
            lg.draw(self.blurCanvases[1-index])
        end
    end

    lg.setCanvas(canvas)
    lg.setBlendMode("add")
    lg.draw(self.blurCanvases[1], 0, 0, 0, 2, 2)

    lg.setCanvas()
    lg.setBlendMode("alpha", "alphamultiply")

    return canvas
end



---@param treshold number
function Bloom:setLuminanceTreshold(treshold)
    self.brightFilterShader:send("u_treshold", treshold)
    self.luminanceTreshold = treshold
end


return Bloom