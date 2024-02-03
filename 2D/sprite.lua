local Vector2 = require "engine.math.vector2"
local Rect = require "engine.math.rect"
local Object = require "engine.3rdparty.classic.classic"


--- @class Sprite
---
--- @field public texture love.Texture | love.SpriteBatch
--- @field public size Vector2
--- @field public color number[]
--- @field public rotation number
--- @field public origin Vector2
--- @field public renderArea Rect
--- @field private _quad love.Quad
---
---@overload fun(texture: love.Texture | love.SpriteBatch, color: number[]?, size: Vector2?, rotation: number?, origin: Vector2?, renderArea: Rect?)
local Sprite = Object:extend()


function Sprite:new(texture, color, size, rotation, origin, renderArea)
    self.texture = texture
    self.size = size or Vector2(1,1)
    self.color = color or {1,1,1,1}
    self.rotation = rotation or 0
    self.origin = origin or Vector2(0,0)
    self.renderArea = renderArea or Rect(Vector2(0,0), Vector2(texture:getDimensions()))

    self._quad = love.graphics.newQuad(0,0,0,0,0,0)
end


---@param pos Vector2
---@param shader love.Shader?
---@param blendMode love.BlendMode?
---@param alphaBlendMode love.BlendAlphaMode?
function Sprite:draw(pos, shader, blendMode, alphaBlendMode)
    self:_updateQuad()

    if shader then
        lg.setShader(shader)
    end

    if blendMode or alphaBlendMode then
        love.graphics.setBlendMode(blendMode or "alpha", alphaBlendMode or "alphamultiply")
    end

    love.graphics.setColor(self.color)
    love.graphics.draw(self.texture, self._quad, pos.x, pos.y, self.rotation, self.size.x, self.size.y, self.origin.x, self.origin.y)
end


---@param pos Vector2
function Sprite:batchAdd(pos)
    self:_updateQuad()

    self.texture:add(self._quad, pos.x, pos.y, self.rotation, self.size.x, self.size.y, self.origin.x, self.origin.y)
    self.texture:setColor(unpack(self.color))
end


---@private
function Sprite:_updateQuad()
    local quadPos, quadSize = self.renderArea.position, self.renderArea.size
    self._quad:setViewport(quadPos.x, quadPos.y, quadSize.width, quadSize.height, self.texture:getDimensions())
end

return Sprite