local BaseRederer = require "engine.3D.renderers.baseRenderer"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local black = {0,0,0,0}
local depthPrePassShader = Utils.newPreProcessedShader([[
#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"
#define Velocity love_Canvases[1]

smooth varying vec4 v_clipPos;
smooth varying vec4 v_prevClipPos;


#ifdef VERTEX
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat4 u_prevTransform;
uniform mat4 u_boneMatrices[MAX_BONE_COUNT];

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(u_boneMatrices, VertexBoneIDs, VertexWeights);
    position = skinMat * position;

    vec4 screenPos = u_viewProj * u_world * position;
    v_clipPos = screenPos;
    v_prevClipPos = u_prevTransform * position;
    
    screenPos.y *= -1.0; // 3 days of my life wasted because of this bullshit
    screenPos.z += 0.00001; // Pre-pass bias to avoid depth conflict on some hardwares
    
    return screenPos;
}
#endif

#ifdef PIXEL
void effect() {
    vec2 pos = v_clipPos.xy / v_clipPos.w;
    vec2 prevPos = v_prevClipPos.xy / v_prevClipPos.w;

    Velocity = vec4(EncodeVelocity(pos - prevPos), 1, 1);
}
#endif
]])


--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): ForwardRenderer
local ForwardRenderer = BaseRederer:extend()


function ForwardRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)
end


--- @param camera Camera
function ForwardRenderer:renderMeshes(camera)
    local viewProj = camera.viewProjectionMatrix

    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshparts)
    end

    lg.setCanvas({self.resultCanvas, self.velocityBuffer, depthstencil = self.depthCanvas})
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
        depthPrePassShader:send("u_prevTransform", "column", self.previousTransformations[meshpart]:toFlatTable())

        if settings.animator then
            depthPrePassShader:send("u_boneMatrices", settings.animator.finalMatrices)
        end

        lg.draw(meshpart.buffer)
    end


    lg.setShader()
    lg.setCanvas()
    lg.setDepthMode()
    lg.setMeshCullMode("none")
    lg.setBlendMode("alpha", "alphamultiply")

    for i, effect in ipairs(self.ppeffects) do
        effect:onPreRender(self, camera)
    end

    ---------------
    -- Rendering --
    ---------------

    lg.setCanvas({self.resultCanvas, depthstencil = self.depthCanvas})
    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add")

    for meshpart, settings in pairs(self.meshparts) do
        local mat = meshpart.material --[[@as ForwardMaterial]]
        mat.viewPosition = camera.position
        mat.worldMatrix = settings.worldMatrix
        mat.viewProjectionMatrix = viewProj

        if settings.animator then
            mat.boneMatrices = settings.animator.finalMatrices
        end

        if settings.onDraw then
            settings.onDraw(meshpart, settings)
        end

        if settings.ignoreLighting then
            meshpart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end
                
                mat:setLightType(getmetatable(light))
                light:applyLighting(mat.shader)

                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, mat.shader)
                end

                meshpart:draw()

                ::continue::
            end
        end
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer