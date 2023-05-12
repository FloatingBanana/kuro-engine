local Vector2 = require "engine.math.vector2"
local Renderer = Object:extend()

local hdrShader = lg.newShader("engine/shaders/postprocessing/hdr.frag")
local brightFilterShader = lg.newShader [[
vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
    vec3 pixel = Texel(texture, texcoords).rgb;
    float brightness = dot(pixel, vec3(0.2126, 0.7152, 0.0722));
    float luminance = max(0.0, brightness - 1.0);

    return vec4(pixel * sign(luminance), 1.0);
}
]]

function Renderer:new(screensize, msaa, hdrExposure, bloomAmount)
    self.screensize = screensize
    self.msaa = msaa
    self.hdrExposure = hdrExposure
    self.bloomAmount = bloomAmount

    -- Setup shaders
    self.blurShader = lg.newShader("engine/shaders/postprocessing/gaussianBlurOptimized.frag")
    self.blurShader:send("texSize", screensize:toFlatTable())

    -- Setup canvases
    self.hdrCanvas = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f", msaa = msaa})
    self.bloomCanvas = lg.newCanvas(WIDTH, HEIGHT, {format = "rgba16f"})
    self.blurCanvases = {
        [true] = lg.newCanvas(screensize.width/2, screensize.height/2),
        [false] = lg.newCanvas(screensize.width/2, screensize.height/2)
    }
end

local cvparams = {depth = true}
function Renderer:beginRendering(clearColor)
    cvparams[1] = self.hdrCanvas
    lg.setCanvas(cvparams)
    lg.clear(clearColor or Color.BLACK)

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")
end

function Renderer:endRendering()
    -- Bright filter pass
    lg.setCanvas(self.bloomCanvas)
    lg.setShader(brightFilterShader)
    lg.draw(self.hdrCanvas)

    -- Bloom
    lg.setShader(self.blurShader)
    lg.setBlendMode("alpha", "premultiplied")
    for i=1, self.bloomAmount*2 do
        local horizontal = (i % 2) == 1
        local blurDir = horizontal and Vector2(1,0) or Vector2(0,1)

        self.blurShader:send("direction", blurDir:toFlatTable())
        lg.setCanvas(self.blurCanvases[horizontal])

        if i==1 then
            lg.draw(self.bloomCanvas, 0,0,0,.5,.5)
        else
            lg.draw(self.blurCanvases[not horizontal])
        end
    end

    lg.setCanvas()

    -- Render final result
    lg.setShader(hdrShader)
    hdrShader:send("bloomBlur", self.blurCanvases[false])
    hdrShader:send("exposure", self.hdrExposure)
    lg.draw(self.hdrCanvas)

    lg.setBlendMode("alpha", "alphamultiply")
    lg.setMeshCullMode("none")
    lg.setDepthMode()
    lg.setShader()
end

return Renderer