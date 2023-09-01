local BaseRederer = require "engine.3DRenderer.renderers.baseRenderer"

local black = Color.BLACK
local depthPrePassShader = lg.newShader [[
#ifdef VERTEX
uniform mat4 u_viewProj;
uniform mat4 u_world;

vec4 position(mat4 transformProjection, vec4 position) {
    vec4 pos = u_viewProj * u_world * position;
    
    // 3 days of my life wasted because of this bullshit
    pos.y *= -1.0;

    // Pre-pass bias to avoid depth conflict on some hardwares
    pos.z += 0.00001;
    
    return pos;
}
#endif

#ifdef PIXEL
void effect() {}
#endif
]]


--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): ForwardRenderer
local ForwardRenderer = BaseRederer:extend()


function ForwardRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)
end


--- @param position Vector3
--- @param view Matrix
--- @param projection Matrix
function ForwardRenderer:renderMeshes(position, view, projection)
    local viewProj = view * projection

    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshparts)
    end

    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.clear(black)

    --------------------
    -- Depth pre-pass --
    --------------------
    -- Calculating depth values beforehand so they don't
    -- get in the way when doing the multi-pass lighting.
    -- Kinda sucks that we have to render everything again
    -- but hey, at least we have depth info for lighting
    -- effects (like SSAO) so it's not that bad.

    lg.setDepthMode("lequal", true)
    lg.setMeshCullMode("back")
    lg.setBlendMode("replace")
    lg.setShader(depthPrePassShader)
    depthPrePassShader:send("u_viewProj", "column", viewProj:toFlatTable())

    for meshpart, settings in pairs(self.meshparts) do
        depthPrePassShader:send("u_world", "column", settings.worldMatrix:toFlatTable())
        lg.draw(meshpart.mesh)
    end


    lg.setShader()
    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self, view, projection)
    end

    ---------------
    -- Rendering --
    ---------------

    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add")

    for meshpart, settings in pairs(self.meshparts) do
        local mat = meshpart.material --[[@as ForwardRenderingMaterial]]
        mat.viewPosition = position
        mat.worldMatrix = settings.worldMatrix
        mat.viewProjectionMatrix = viewProj

        if settings.onDraw then
            settings.onDraw(meshpart, settings)
        end

        if settings.ignoreLighting then
            meshpart:draw()
        else
            for i, light in ipairs(self.lights) do
                mat:setLightType(getmetatable(light))
                light:applyLighting(mat.shader)

                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, mat.shader)
                end

                meshpart:draw()
            end
        end
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer