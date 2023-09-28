local Stack = require "engine.collections.stack"
local Vector3 = require "engine.math.vector3"
local AmbientLight = require "engine.3DRenderer.lights.ambientLight"
local DeferredRenderer = require "engine.3DRenderer.renderers.deferredRenderer"
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

local defines = {
    accurate = "SAMPLE_DEPTH_ACCURATE",
    naive = "SAMPLE_DEPTH_NAIVE",
    deferred = "SAMPLE_DEPTH_DEFERRED"
}

local boxBlurShader = lg.newShader(Utils.preprocessShader((lfs.read("engine/shaders/postprocessing/boxBlur.frag"))))
boxBlurShader:send("size", 2)


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
local SSAO = BaseEffect:extend()


function SSAO:new(screenSize, kernelSize, kernelRadius, algorithm)
    self.kernel = Stack()
    self.ssaoCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "r8"})
    self.blurCanvas = lg.newCanvas(screenSize.width, screenSize.height, {format = "r8"})
    self.dummySquare = Utils.newSquareMesh(screenSize)
    self.algorithm = algorithm or "deferred"
    self.kernelSize = kernelSize
    self.kernelRadius = kernelRadius

    self.shader = Utils.newPreProcessedShader("engine/shaders/3D/deferred/ssao.frag", {defines[self.algorithm]})

    self.shader:send("u_noiseScale", (screenSize / 4):toFlatTable())
    self.shader:send("u_noiseTex", ssaoNoise)
    self:setKernelSize(kernelSize)
    self:setKernelRadius(kernelRadius)
end


--- @param renderer BaseRenderer
--- @param camera Camera
function SSAO:onPreRender(renderer, camera)
    lg.setCanvas(self.ssaoCanvas)
    lg.setShader(self.shader)
    lg.clear()

    self.shader:send("u_projection", "column", camera.projectionMatrix:toFlatTable())

    if self.algorithm == "deferred" then
        assert(renderer:is(DeferredRenderer), "SSAO's 'deferred' algorithm can only be used in a deferred renderer")
        
        --- @cast renderer DeferredRenderer
        self.shader:send("u_gPosition", renderer.gbuffer.position)
        self.shader:send("u_gNormal", renderer.gbuffer.normal)
        self.shader:send("u_view", "column", camera.viewMatrix:toFlatTable())
    else
        self.shader:send("u_invProjection", "column", camera.projectionMatrix.inverse:toFlatTable())
        self.shader:send("u_depthBuffer", renderer.depthCanvas)
    end

    lg.draw(self.dummySquare)

    lg.setCanvas(self.blurCanvas)
    lg.setShader(boxBlurShader)
    lg.clear()

    lg.draw(self.ssaoCanvas)

    lg.setCanvas()
    lg.setShader()
end


function SSAO:onLightRender(light, shader)
    if light:is(AmbientLight) then
        shader:send("u_ssaoTex", self.blurCanvas)
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