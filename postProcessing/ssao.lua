local Stack            = require "engine.collections.stack"
local Vector3          = require "engine.math.vector3"
local AmbientLight     = require "engine.3D.lights.ambientLight"
local DeferredRenderer = require "engine.3D.renderers.deferredRenderer"
local BaseEffect       = require "engine.postProcessing.basePostProcessingEffect"
local Utils            = require "engine.misc.utils"
local ShaderEffect     = require "engine.misc.shaderEffect"
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

local gaussianBlurShader = ShaderEffect("engine/shaders/postprocessing/gaussianBlurOptimized.frag")

local hdir = {1,0}
local vdir = {0,1}


--- @class SSAO: BasePostProcessingEffect
---
--- @field private kernel Stack
--- @field private ssaoCanvas love.Canvas
--- @field private blurCanvas love.Canvas
--- @field private shader ShaderEffect
--- @field private dummySquare love.Mesh
--- @field public kernelSize integer
--- @field public kernelRadius number
---
--- @overload fun(screenSize: Vector2, kernelSize: integer, kernelRadius: number): SSAO
local SSAO = BaseEffect:extend("SSAO")


function SSAO:new(screenSize, kernelSize, kernelRadius)
    local ssaoSize = screenSize / 2

    self.kernel = Stack()
    self.ssaoCanvas = love.graphics.newCanvas(ssaoSize.width, ssaoSize.height, {format = "r8"})
    self.blurCanvas = love.graphics.newCanvas(ssaoSize.width, ssaoSize.height, {format = "r8"})
    self.dummySquare = Utils.newSquareMesh(ssaoSize)
    self.kernelSize = kernelSize
    self.kernelRadius = kernelRadius

    self.shader = ShaderEffect("engine/shaders/postprocessing/ssao.frag")

    self.shader:sendUniform("u_noiseScale", (ssaoSize / 4):toFlatTable())
    self.shader:sendUniform("u_noiseTex", ssaoNoise)
    self:setKernelSize(kernelSize)
    self:setKernelRadius(kernelRadius)
end


function SSAO:onPostRender(renderer, camera, canvas)
    love.graphics.setCanvas(self.ssaoCanvas)
    love.graphics.clear()
    self.shader:use()

    self.shader:sendRendererUniforms(renderer)
    self.shader:sendCameraUniforms(camera)
    love.graphics.draw(self.dummySquare)

    gaussianBlurShader:use()
    gaussianBlurShader:sendUniform("direction", hdir)
    love.graphics.setCanvas(self.blurCanvas)
    love.graphics.clear()
    love.graphics.draw(self.ssaoCanvas)

    gaussianBlurShader:sendUniform("direction", vdir)
    love.graphics.setCanvas(self.ssaoCanvas)
    love.graphics.clear()
    love.graphics.draw(self.blurCanvas)

    return canvas
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

    self.shader:sendUniform("u_samples", unpack(self.kernel))
    self.shader:sendUniform("u_kernelSize", size)
end


--- @param radius number
function SSAO:setKernelRadius(radius)
    self.shader:sendUniform("u_kernelRadius", radius)
    self.kernelRadius = radius
end


return SSAO