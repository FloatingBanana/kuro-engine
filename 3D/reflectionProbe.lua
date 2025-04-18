local Object          = require "engine.3rdparty.classic.classic"
local Vector2         = require "engine.math.vector2"
local Camera3D        = require "engine.misc.camera3d"
local Vector3         = require "engine.math.vector3"
local Quaternion      = require "engine.math.quaternion"
local Matrix3         = require "engine.math.matrix3"
local CubemapUtils    = require "engine.misc.cubemapUtils"

local camera = Camera3D(Vector3(0), Quaternion.Identity(), math.rad(90), Vector2(1), 0.1, 100)

---@class ReflectionProbe: Object
---
---@field public position Vector3
---@field public environmentMap love.Texture
---@field public reflectionMap love.Texture
---
---@overload fun(position: Vector3): ReflectionProbe
local ReflectionProbe = Object:extend("ReflectionProbe")

function ReflectionProbe:new(position)
    self.position = position

    self.environmentMap = nil
    self.reflectionMap = nil
end


---@param renderer BaseRenderer
function ReflectionProbe:bake(renderer, nearDistance, farDistance)
    camera.position = self.position
    camera.nearPlane = nearDistance
    camera.farPlane = farDistance
    local sidesData = {}


    for s, side in ipairs(CubemapUtils.cubeSides) do
        camera.rotation = Quaternion.CreateFromRotationMatrix(Matrix3.CreateFromDirection(side.dir, side.up))
        -- camera.rotation = side.viewMatrix.rotation:invert()

        sidesData[s] = renderer:render(camera):newImageData(1)
    end
    -- For some reason the y+ and y- faces are swiched on rendering, idk why...
    sidesData[3], sidesData[4] = sidesData[4], sidesData[3]

    self:bakeFromEnvironmentMap(love.graphics.newCubeImage(sidesData, {mipmaps = true}))
end


---@param envMap love.Texture
function ReflectionProbe:bakeFromEnvironmentMap(envMap)
    self.environmentMap = envMap
    self.reflectionMap = CubemapUtils.environmentRadianceMap(envMap, Vector2(envMap:getPixelDimensions()), 32)
end

return ReflectionProbe