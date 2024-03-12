local BaseEffect = require "engine.postProcessing.basePostProcessingEffect"

local aberrationShader = [[
    uniform vec2 u_offset;
    
    vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
        return vec4(
            Texel(texture, texcoords + vec2( 1, 0) * u_offset).r,
            Texel(texture, texcoords + vec2(-1, 0) * u_offset).g,
            Texel(texture, texcoords + vec2( 0, 1) * u_offset).b,
            Texel(texture, texcoords).a
        );
    }
]]


--- @class ChromaticAberration: BasePostProcessingEffect
---
--- @field private effectCanvas love.Canvas
--- @field private shader love.Shader
--- @field public offset number
--- @field public screenSize Vector2
---
--- @overload fun(screenSize: Vector2, offset: number): ChromaticAberration
local ChromaticAberration = BaseEffect:extend("ChromaticAberration")


function ChromaticAberration:new(screenSize, offset)
    self.effectCanvas = love.graphics.newCanvas(screenSize.width, screenSize.height)
    self.shader = love.graphics.newShader(aberrationShader)
    self.offset = offset
    self.screenSize = screenSize

    self:setOffset(offset)
end


function ChromaticAberration:onPostRender(renderer, canvas, camera)
    love.graphics.setCanvas(self.effectCanvas)
    love.graphics.setShader(self.shader)

    love.graphics.draw(canvas)

    love.graphics.setCanvas()
    love.graphics.setShader()

    return self.effectCanvas
end


--- @param offset number
function ChromaticAberration:setOffset(offset)
    self.shader:send("u_offset", self.screenSize.inverse:multiply(offset):toFlatTable())
    self.offset = offset
end


return ChromaticAberration