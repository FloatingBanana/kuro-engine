local Stack            = require "engine.collections.stack"
local Vector3          = require "engine.math.vector3"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local DeferredRenderer = require "engine.3D.renderers.deferredRenderer"
local BaseEffect       = require "engine.postProcessing.basePostProcessingEffect"
local Utils            = require "engine.misc.utils"
local Lume             = require "engine.3rdparty.lume"


--------------------------------
-- Buildig ssao noise texture --
--------------------------------
local ssaoNoiseData = love.image.newImageData(4, 4, "rg8")
for i=0, 15 do
    local x = i % 4
    local y = math.floor(i/4)

    ssaoNoiseData:setPixel(x, y, math.random(), math.random(), 0, 0)
end
local ssaoNoise = love.graphics.newImage(ssaoNoiseData)
ssaoNoise:setWrap("repeat")
ssaoNoiseData:release()

local defines = {
    accurate = "SAMPLE_DEPTH_ACCURATE",
    naive = "SAMPLE_DEPTH_NAIVE",
    deferred = "SAMPLE_DEPTH_DEFERRED"
}

local gaussianBlurShader = Utils.newPreProcessedShader("engine/shaders/postprocessing/gaussianBlurOptimized.frag")


--- @class SSAO: BasePostProcessingEffect
---
--- @field private kernel Stack
--- @field private ssaoCanvas love.Canvas
--- @field private blurCanvas love.Canvas
--- @field private shader love.Shader
--- @field private dummySquare love.Mesh
--- @field private algorithm string
--- @field public kernelSize integer
--- @field public kernelRadius number
---
--- @overload fun(screenSize: Vector2, kernelSize: integer, kernelRadius: number, algorithm: "accurate" | "naive" | "deferred" | nil): SSAO
local SSAO = BaseEffect:extend("SSAO")


function SSAO:new(screenSize, kernelSize, kernelRadius, algorithm)
    local ssaoSize = screenSize / 2

    self.kernel = Stack()
    self.ssaoCanvas = love.graphics.newCanvas(ssaoSize.width, ssaoSize.height, {format = "r8"})
    self.blurCanvas = love.graphics.newCanvas(ssaoSize.width, ssaoSize.height, {format = "r8"})
    self.dummySquare = Utils.newSquareMesh(ssaoSize)
    self.algorithm = algorithm or "deferred"
    self.kernelSize = kernelSize
    self.kernelRadius = kernelRadius

    self.shader = Utils.newPreProcessedShader("engine/shaders/3D/deferred/ssao.frag", {defines[self.algorithm]})

    self.shader:send("u_noiseScale", (ssaoSize / 4):toFlatTable())
    self.shader:send("u_noiseTex", ssaoNoise)
    self:setKernelSize(kernelSize)
    self:setKernelRadius(kernelRadius)
end


--- @param renderer BaseRenderer
--- @param camera Camera3D
function SSAO:onPreRender(renderer, camera)
    assert(self.algorithm ~= "deferred" or renderer:is(DeferredRenderer), "SSAO's 'deferred' algorithm can only be used in a deferred renderer")

    love.graphics.setCanvas(self.ssaoCanvas)
    love.graphics.setShader(self.shader)

    renderer:sendCommonRendererBuffers(self.shader, camera)
    love.graphics.draw(self.dummySquare)

    love.graphics.setShader(gaussianBlurShader)

    gaussianBlurShader:send("direction", {1,0})
    love.graphics.setCanvas(self.blurCanvas)
    love.graphics.draw(self.ssaoCanvas)

    gaussianBlurShader:send("direction", {0,1})
    love.graphics.setCanvas(self.ssaoCanvas)
    love.graphics.draw(self.blurCanvas)

    love.graphics.setCanvas()
    love.graphics.setShader()
end


function SSAO:onLightRender(light, shader)
    if light:is(AmbientLight) then
        shader:send("u_ssaoTex", self.ssaoCanvas)
    end
end


--- @param size integer
function SSAO:setKernelSize(size)
    self.kernel = Stack()
    self.kernelSize = size

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
    self.kernelRadius = radius
end


return SSAO