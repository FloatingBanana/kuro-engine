local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

local brightFilterShader = [[
uniform float u_treshold;
const vec3 colorBalance = vec3(0.2126, 0.7152, 0.0722);

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 pixel = Texel(texture, texcoords).rgb;
    float brightness = dot(pixel, colorBalance);
    float luminance = max(0.0, brightness - u_treshold);
    
    return vec4(pixel * sign(luminance), 1.0);
}
]]


--- @class Bloom: BasePostProcessingEffect
---
--- @field strenght integer
--- @field private blurShader love.Shader
--- @field private brightFilterShader love.Shader
--- @field private bloomCanvas love.Canvas
--- @field private blurCanvases love.Canvas[]
---
--- @overload fun(screenSize: Vector2, strenght: integer, luminanceTreshold: number): Bloom
local Bloom = BaseEffect:extend()


function Bloom:new(screenSize, strenght, luminanceTreshold)
    local blurShaderCode = lfs.read("engine/shaders/postprocessing/gaussianBlurOptimized.frag")

    self.strenght = strenght
    self.blurShader = lg.newShader(Utils.preprocessShader(blurShaderCode))
    self.brightFilterShader = lg.newShader(brightFilterShader)

    self.bloomCanvas = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rgba16f"})
    self.blurCanvases = {
        [0] = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rgba16f"}),
        [1] = lg.newCanvas(screenSize.width/2, screenSize.height/2, {format = "rgba16f"})
    }

    self.bloomCanvas:setFilter("linear", "linear")
    self.blurCanvases[0]:setFilter("linear", "linear")
    self.blurCanvases[1]:setFilter("linear", "linear")

    self:setLuminanceTreshold(luminanceTreshold)
end


function Bloom:onPostRender(device, canvas, camera)
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
end


return Bloom