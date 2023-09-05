local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"

-- https://vicrucann.github.io/tutorials/osg-shader-fog/
local hdrShader = Utils.preprocessShader((lfs.read("engine/shaders/postprocessing/fog.frag")))


--- @class Fog: BasePostProcessingEffect
---
--- @field private hdrCanvas love.Canvas
--- @field private shader love.Shader
--- @field public color table
---
--- @overload fun(screenSize: Vector2, min: number, max: number, color: table): Fog
local Fog = BaseEffect:extend()


function Fog:new(screenSize, min, max, color)
    self.fogCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "rgba16f"})
    self.shader = lg.newShader(hdrShader)

    self:setTreshold(min, max)
    self:setColor(color)
end


function Fog:onPostRender(device, canvas, camera)
    lg.setCanvas(self.fogCanvas)
    lg.setShader(self.shader)

    self.shader:send("u_depthBuffer", device.depthCanvas)
    self.shader:send("u_viewPos", camera.position:toFlatTable())
    self.shader:send("u_invViewProj", "column", camera.viewProjectionMatrix:invert():toFlatTable())
    lg.draw(canvas)

    lg.setCanvas()
    lg.setShader()

    return self.fogCanvas
end


--- @param min number
--- @param max number
function Fog:setTreshold(min, max)
    self.shader:send("u_minMaxDistance", {min, max})
end


--- @param color table
function Fog:setColor(color)
    self.shader:send("u_fogColor", color)
end


return Fog