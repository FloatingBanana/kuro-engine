local Vector3 = require "engine.math.vector3"
local Quaternion = require "engine.math.quaternion"


--- @class ModelAnimationNode: Object
---
--- @field public name string
--- @field private _positionKeys {time: number, value: Vector3}[]
--- @field private _rotationKeys {time: number, value: Quaternion}[]
--- @field private _scaleKeys {time: number, value: Vector3}[]
local AnimNode = Object:extend()


function AnimNode:new(aiAnimNode)
    self.name = aiAnimNode:node_name()
    self._positionKeys = {}
    self._rotationKeys = {}
    self._scaleKeys = {}

    for i, key in ipairs(aiAnimNode:position_keys()) do
        self._positionKeys[i] = {time = key.time, value = Vector3(unpack(key.value))}
    end

    for i, key in ipairs(aiAnimNode:rotation_keys()) do
        -- for some fucking stupid reason moonassimp quaternion values are in the order of {w, x, y, z} (i'm tired boss)
        self._rotationKeys[i] = {time = key.time, value = Quaternion(key.value[2], key.value[3], key.value[4], key.value[1])}
    end

    for i, key in ipairs(aiAnimNode:scaling_keys()) do
        self._scaleKeys[i] = {time = key.time, value = Vector3(unpack(key.value))}
    end
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
        prevPos * (1-posProgress) + nextPos * posProgress,
        Quaternion.Slerp(prevRot, nextRot, rotProgress),
        prevScale * (1-scaleProgress) + nextScale * scaleProgress
end

return AnimNode