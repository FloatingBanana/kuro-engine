local Stack = require "engine.collections.stack"
local Vector3 = require "engine.math.vector3"
local BaseEffect = require "engine.3DRenderer.postProcessing.basePostProcessingEffect"
local SSAO = BaseEffect:extend()

-- TODO: Add forward rendering support

local ssaoNoiseData = love.image.newImageData(4, 4, "rg8")
for i=0, 15 do
    local x = i % 4
    local y = math.floor(i/4)

    ssaoNoiseData:setPixel(x, y, math.random(), math.random(), 0, 0)
end
local ssaoNoise = lg.newImage(ssaoNoiseData)
ssaoNoise:setWrap("repeat")
ssaoNoiseData:release()


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

function SSAO:deferredPreRender(device, shader, gbuffer, view, projection)
    lg.setCanvas(self.ssaoCanvas)
    lg.setShader(self.shader)
    lg.clear()

    self.shader:send("u_gPosition", gbuffer.position)
    self.shader:send("u_gNormal", gbuffer.normal)
    self.shader:send("u_view", "column", view:toFlatTable())
    self.shader:send("u_projection", "column", projection:toFlatTable())

    lg.draw(self.dummySquare)
    lg.setCanvas()

    shader:send("u_ssaoTex", self.ssaoCanvas)
end

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

function SSAO:setKernelRadius(radius)
    self.shader:send("u_kernelRadius", radius)
end

return SSAO