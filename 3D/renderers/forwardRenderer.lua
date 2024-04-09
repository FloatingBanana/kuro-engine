local BaseRederer = require "engine.3D.renderers.baseRenderer"
local Utils = require "engine.misc.utils"
local lg = love.graphics

local black = {0,0,0,0}
local depthPrePassShader = Utils.newPreProcessedShader([[
#pragma language glsl3
#pragma include "engine/shaders/incl_utils.glsl"

varying vec4 v_clipPos;
varying vec4 v_prevClipPos;


#ifdef VERTEX
in vec4 VertexBoneIDs;
in vec4 VertexWeights;

uniform mat4 uViewProjMatrix;
uniform mat4 uWorldMatrix;
uniform mat4 uPrevTransform;
uniform mat4 uBoneMatrices[MAX_BONE_COUNT];

vec4 position(mat4 transformProjection, vec4 position) {
    mat4 skinMat = GetSkinningMatrix(uBoneMatrices, VertexBoneIDs, VertexWeights);
    position = skinMat * position;

    vec4 screenPos = uViewProjMatrix * uWorldMatrix * position;
    v_clipPos = screenPos;
    v_prevClipPos = uPrevTransform * position;
    
    screenPos.y *= -1.0; // 3 days of my life wasted because of this bullshit
    screenPos.z += 0.00001; // Pre-pass bias to avoid depth conflict on some hardwares
    
    return screenPos;
}
#endif

#ifdef PIXEL
out vec4 oVelocity;

void effect() {
    vec2 pos = v_clipPos.xy / v_clipPos.w;
    vec2 prevPos = v_prevClipPos.xy / v_prevClipPos.w;

    oVelocity = vec4(EncodeVelocity(pos - prevPos), 1, 1);
}
#endif
]])


--- @class ForwardRenderer: BaseRenderer
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): ForwardRenderer
local ForwardRenderer = BaseRederer:extend("ForwardRenderer")


function ForwardRenderer:new(screensize, postProcessingEffects)
    BaseRederer.new(self, screensize, postProcessingEffects)
end


--- @param camera Camera3D
function ForwardRenderer:renderMeshes(camera)
    for i, light in ipairs(self.lights) do
        light:generateShadowMap(self.meshParts)
    end

    lg.setCanvas({self.velocityBuffer, depthstencil = self.depthCanvas})
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
    self:sendCommonRendererBuffers(depthPrePassShader, camera)

    for i, config in ipairs(self.meshParts) do
        self:sendCommonMeshBuffers(depthPrePassShader, config)
        lg.draw(config.meshPart.buffer)
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
    lg.clear(true, false, false)
    lg.setDepthMode("lequal", false)
    lg.setMeshCullMode("back")
    lg.setBlendMode("add")

    while self.meshParts:peek() do
        local config = self.meshParts:pop() --[[@as MeshPartConfig]]
        local mat = config.meshPart.material --[[@as ForwardMaterial]]

        if config.ignoreLighting then
            self:sendCommonRendererBuffers(mat.shader, camera)
            self:sendCommonMeshBuffers(mat.shader, config)
            config.meshPart:draw()
        else
            for i, light in ipairs(self.lights) do
                if not light.enabled then goto continue end

                mat:setLightType(getmetatable(light))
                light:applyLighting(mat.shader)
                self:sendCommonRendererBuffers(mat.shader, camera) --! Sending this amount of data every single pass isn't really a good idea, gonna fix it later 
                self:sendCommonMeshBuffers(mat.shader, config)

                for j, effect in ipairs(self.ppeffects) do
                    effect:onLightRender(light, mat.shader)
                end

                config.meshPart:draw()
                ::continue::
            end
        end

        self:recycleConfigTable(config)
    end


    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
end


return ForwardRenderer