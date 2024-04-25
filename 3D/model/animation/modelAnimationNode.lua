local Vector3    = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"
local Object     = require "engine.3rdparty.classic.classic"


--- @class ModelAnimationNode: Object
---
--- @field public name string
--- @field private _positionKeys {time: number, value: Vector3}[]
--- @field private _rotationKeys {time: number, value: Quaternion}[]
--- @field private _scaleKeys {time: number, value: Vector3}[]
local AnimNode = Object:extend("ModelAnimationNode")


function AnimNode:new(animNodeData)
    self.name = animNodeData.name
    self._positionKeys = animNodeData.positionKeys
    self._rotationKeys = animNodeData.rotationKeys
    self._scaleKeys = animNodeData.scaleKeys
end


local function findInterpolationKeys(keyList, time)
    for i, nextKey in ipairs(keyList) do
        if time < nextKey.time then
            local prevKey = keyList[i-1] or nextKey

            return prevKey.value, nextKey.value, (time - prevKey.time) / (nextKey.time - prevKey.time)
        end
    end
end


---@param time number
---@return Vector3
---@return Quaternion
---@return Vector3
function AnimNode:getInterpolated(time)
    local prevPos, nextPos, posProgress = findInterpolationKeys(self._positionKeys, time)
    local prevRot, nextRot, rotProgress = findInterpolationKeys(self._rotationKeys, time)
    local prevScale, nextScale, scaleProgress = findInterpolationKeys(self._scaleKeys, time)

    return
        Vector3.Lerp(prevPos, nextPos, posProgress),
        Quaternion.Slerp(prevRot, nextRot, rotProgress),
        Vector3.Lerp(prevScale, nextScale, scaleProgress)
end

return AnimNode