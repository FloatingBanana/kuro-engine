local Stack = require "engine.collections.stack"
local Vector3 = require "engine.math.vector3"
local AmbientLight = require "engine.3DRenderer.lights.ambientLight"
local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"


-- TODO: Add forward rendering support

--------------------------------
-- Buildig ssao noise texture --
--------------------------------
local ssaoNoiseData = love.image.newImageData(4, 4, "rg8")
for i=0, 15 do
    local x = i % 4
    local y = math.floor(i/4)

    ssaoNoiseData:setPixel(x, y, math.random(), math.random(), 0, 0)
end
local ssaoNoise = lg.newImage(ssaoNoiseData)
ssaoNoise:setWrap("repeat")
ssaoNoiseData:release()



--- @class SSAO: BasePostProcessingEffect
---
--- @field private kernel Stack
--- @field private ssaoCanvas love.Canvas
--- @field private shader love.Shader
--- @field private dummySquare love.Mesh
---
--- @overload fun(screenSize: Vector2, kernelSize: integer, kernelRadius: number): SSAO
local SSAO = BaseEffect:extend()


function SSAO:new(screenSize, kernelSize, kernelRadius)
    self.kernel = Stack()
    self.ssaoCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "r8"})
    self.shader = lg.newShader("engine/shaders/3D/deferred/ssao.frag")
    self.dummySquare = Utils.newSquareMesh(screenSize)

    self.shader:send("u_noiseScale", (screenSize / 4):toFlatTable())
    self.shader:send("u_noiseTex", ssaoNoise)
    self:setKernelSize(kernelSize)
    self:setKernelRadius(kernelRadius)
end


function SSAO:onPreRender(device, view, projection)
    lg.setCanvas(self.ssaoCanvas)
    lg.setShader(self.shader)
    lg.clear()

    self.shader:send("u_gPosition", device.gbuffer.position)
    self.shader:send("u_gNormal", device.gbuffer.normal)
    self.shader:send("u_view", "column", view:toFlatTable())
    self.shader:send("u_projection", "column", projection:toFlatTable())

    lg.draw(self.dummySquare)
    lg.setCanvas()
end


function SSAO:onLightRender(light, shader)
    if light:is(AmbientLight) then
        shader:send("u_ssaoTex", self.ssaoCanvas)
    end
end


--- @param size integer
function SSAO:setKernelSize(size)
    self.kernel = Stack()

    for i=0, size-1 do
        local sample = Vector3(
            math.random() * 2 - 1,
            math.random() * 2 - 1,
            math.random()
        )

        local scale = i / size
        scale = Lume.lerp(0.1, 1, scale*scale)

        sample:normalize():multiply(scale)
        self.kernel:push({sample:split()})
    end

    self.shader:send("u_samples", unpack(self.kernel))
    self.shader:send("u_kernelSize", size)
end


--- @param radius number
function SSAO:setKernelRadius(radius)
    self.shader:send("u_kernelRadius", radius)
end


return SSAO