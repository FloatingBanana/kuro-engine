local Renderer = Object:extend()

local black = Color.BLACK
local cvparams = {depth = true}

function Renderer:new(renderType, screensize, postProcessingEffects)
    self.renderType = renderType
    self.screensize = screensize
    self.ppeffects = postProcessingEffects

    self.resultCanvas = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"})
    self.dummySquare = Utils.newSquareMesh(screensize)

    -- Maybe it would be better to make diferent subclasses for different rendering techniques,
    -- especially if I plan to add more of them, but i'm too lazy so for now this will do the job.
    if renderType == "deferred" then
        self.gbuffer = {
            position   = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"}),
            normal     = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"}),
            albedoSpec = lg.newCanvas(screensize.width, screensize.height)
        }
    elseif renderType == "forward" then
        -- nothing
    else
        error("Rendering technique not supported: "..tostring(renderType))
    end
end

function Renderer:beginRendering(clearColor)
    cvparams[1] = self.resultCanvas
    lg.setCanvas(cvparams)
    lg.clear(clearColor or black)

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")
end

function Renderer:beginDeferredRendering(clearColor)
    lg.setCanvas({self.gbuffer.position, self.gbuffer.normal, self.gbuffer.albedoSpec, depth = true})
    lg.clear(black, black, clearColor or black)

    lg.setDepthMode("lequal", true)
    lg.setBlendMode("replace")
    lg.setMeshCullMode("back")
end

function Renderer:endDeferredRendering(deferredLightingShader, position, view, projection)
    lg.setCanvas()
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setMeshCullMode("none")
    lg.setDepthMode()

    for i, effect in ipairs(self.ppeffects) do
        effect:deferredPreRender(self, deferredLightingShader, self.gbuffer, view, projection)
    end

    deferredLightingShader:send("u_viewPosition", position:toFlatTable())
    deferredLightingShader:send("u_gPosition",    self.gbuffer.position)
    deferredLightingShader:send("u_gNormal",      self.gbuffer.normal)
    deferredLightingShader:send("u_gAlbedoSpec",  self.gbuffer.albedoSpec)

    lg.setCanvas(self.resultCanvas)
    lg.setShader(deferredLightingShader)
    lg.draw(self.dummySquare)
    lg.setShader()

    self:endRendering(view, projection)
end

function Renderer:endRendering(view, projection)
    lg.setCanvas()

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:applyPostRender(self, result, view, projection)
    end

    lg.draw(result)

    lg.setBlendMode("alpha", "alphamultiply")
    lg.setMeshCullMode("none")
    lg.setDepthMode()
    lg.setShader()
end

return Renderer