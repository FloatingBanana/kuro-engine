local Object          = require "engine.3rdparty.classic.classic"
local Vector2         = require "engine.math.vector2"
local Camera3D        = require "engine.misc.camera3d"
local Vector3         = require "engine.math.vector3"
local Quaternion      = require "engine.math.quaternion"
local BoundingBox     = require "engine.math.boundingBox"
local SH9Color        = require "engine.math.SH9Color"
local CubemapUtils    = require "engine.misc.cubemapUtils"
local Matrix3         = require "engine.math.matrix3"

local camera = Camera3D(Vector3(0), Quaternion.Identity(), math.rad(90), Vector2(1), 0.1, 100, "perspective")


---@class IrradianceVolume: Object
---
---@field public transform Matrix4
---@field public gridSize Vector3
---@field public probes SH9Color[]
---@field public probeBuffer love.Image
---
---@overload fun(transform: Matrix4, gridSize: Vector3): IrradianceVolume
local IrradianceVolume = Object:extend("IrradianceVolume")

function IrradianceVolume:new(transform, gridSize)
    self.transform = transform
    self.gridSize = gridSize
    self.probes = {}
    self.probeBuffer = nil

    self:mapProbes(function(...)
        return SH9Color()
    end)

    assert(self:getProbeCount() > 0, "The number of probes in each axis must be greater than 0.")
end


---@param f fun(probe: SH9Color, index: integer): SH9Color
function IrradianceVolume:mapProbes(f)
    local width = math.ceil(math.sqrt(self:getProbeCount()))
    local height = math.ceil(self:getProbeCount() / width)

    local bufferData = love.image.newImageData(width*3, height*3, "rg11b10f")

    for p=1, self:getProbeCount() do
        local probe = f(self.probes[p], p)
        self.probes[p] = probe

        local mx = (p-1) % width
        local my = math.floor((p-1) / width)

        for bx=0, 2 do
            for by=0, 2 do
                bufferData:setPixel(mx*3+bx, my*3+by, probe[by*3+bx+1]:toFlatTable())
            end
        end
    end

    self.probeBuffer = love.graphics.newImage(bufferData, {linear = true, mipmaps = false})
    self.probeBuffer:setWrap("clampzero", "clampzero")
    self.probeBuffer:setFilter("nearest", "nearest")

    bufferData:release()
end


---@param renderer BaseRenderer
---@param nearDistance number
---@param farDistance number
function IrradianceVolume:bake(renderer, nearDistance, farDistance)
    camera.farPlane = nearDistance
    camera.nearPlane = farDistance

    self:mapProbes(function(probe, index)
        local cell = self:getCell(index)
        local sidesData = {}

        camera.position = self:getPositionFromCell(cell)

        for s, side in ipairs(CubemapUtils.cubeSides) do
            camera.rotation = Quaternion.CreateFromRotationMatrix(Matrix3.CreateFromDirection(side.dir, side.up))

            sidesData[s] = renderer:render(camera):newImageData(1)
        end
        -- For some reason the y+ and y- faces are swiched on rendering, idk why...
        sidesData[3], sidesData[4] = sidesData[4], sidesData[3]

        local envMap = love.graphics.newCubeImage(sidesData, {linear = true})
        local irrMap = CubemapUtils.getIrradianceMap(envMap, Vector2(envMap:getPixelDimensions()))

        return SH9Color.CreateFromCubeMap(irrMap)
    end)
end


---@param envMap love.Texture
function IrradianceVolume:bakeFromEnvironmentMap(envMap)
    local irrMap = CubemapUtils.getIrradianceMap(envMap, Vector2(envMap:getPixelDimensions()))

    self:mapProbes(function(probe, index)
        return SH9Color.CreateFromCubeMap(irrMap)
    end)
end


---@param color Vector3
function IrradianceVolume:bakeFromSolidColor(color)
    self:mapProbes(function(probe, index)
        return SH9Color(color, Vector3(0), Vector3(0), Vector3(0), Vector3(0), Vector3(0), Vector3(0), Vector3(0), Vector3(0))
    end)
end



---@return integer
function IrradianceVolume:getProbeCount()
    return self.gridSize.width * self.gridSize.height * self.gridSize.depth
end


-- https://stackoverflow.com/questions/7367770/how-to-flatten-or-index-3d-array-in-1d-array

---@param index integer
---@return Vector3
function IrradianceVolume:getCell(index)
    assert(index > 0 and index <= self:getProbeCount(), "Index is out of bounds")
    index = index - 1

    local width = self.gridSize.width
    local height = self.gridSize.height

    local z = math.floor(index / (width * height))
    index = index - (z * width * height)
    local y = index / width
    local x = index % width
    return Vector3(x, y, z):floor()
end



---@param cell Vector3
---@return integer
function IrradianceVolume:getIndex(cell)
    assert(cell.x >= 0 and cell.y >= 0 and cell.z >= 0 and cell <= self.gridSize, "Cell is out of bounds")

    return (cell.z * self.gridSize.width * self.gridSize.height) + (cell.y * self.gridSize.width) + cell.x + 1
end



---@param cell Vector3
---@return Vector3
function IrradianceVolume:getPositionFromCell(cell)
    local cellCenter = self.gridSize.inverse * 0.5
    local probePos = (cell / self.gridSize) + cellCenter - 0.5

    return probePos:transform(self.transform)
end



---@param pos Vector3
---@return Vector3
function IrradianceVolume:getNearestCell(pos)
    local localPos = pos:clone():transform(self.transform.inverse)
    localPos = (localPos + 0.5) * self.gridSize

    return localPos:floor()
end



---@param pos Vector3
---@return Vector3, Vector3, Vector3, Vector3, Vector3, Vector3, Vector3, Vector3
function IrradianceVolume:getNeighborCells(pos)
    local localPos = pos:clone():transform(self.transform.inverse)
    localPos = (localPos + 0.5) * self.gridSize

    local nx = localPos.x % 1 > 0.5 and 1 or -1
    local ny = localPos.y % 1 > 0.5 and 1 or -1
    local nz = localPos.z % 1 > 0.5 and 1 or -1

    localPos:floor()

    return
        localPos,
        Vector3(nx, 0, 0):add(localPos),
        Vector3( 0,ny, 0):add(localPos),
        Vector3(nx,ny, 0):add(localPos),
        Vector3( 0, 0,nz):add(localPos),
        Vector3(nx, 0,nz):add(localPos),
        Vector3( 0,ny,nz):add(localPos),
        Vector3(nx,ny,nz):add(localPos)
end


---@return BoundingBox
function IrradianceVolume:getVolumeBoundingBox()
    return BoundingBox(Vector3(-0.5), Vector3(0.5)):transform(self.transform)
end



---@param cell Vector3
---@return BoundingBox
function IrradianceVolume:getCellBoundingBox(cell)
    local tl = cell / self.gridSize - 0.5
    return BoundingBox(tl, tl + self.gridSize.inverse):transform(self.transform)
end



return IrradianceVolume