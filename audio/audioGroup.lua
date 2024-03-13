local Object = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Lume = require "engine.3rdparty.lume"

---@class AudioGroup: Object
---
---@field public volume number
---@field public pitch number
---@field public position Vector3
---@field public velocity Vector3
---@field public highgain number
---@field public lowgain number
---
---@field private _volume number
---@field private _pitch number
---@field private _position Vector3
---@field private _velocity Vector3
---@field private _highgain number
---@field private _lowgain number
---
---@overload fun(): AudioGroup
local AudioGroup = Object:extend("AudioGroup")

function AudioGroup:new()
    self._volume = 1
    self._pitch = 1
    self._velocity = Vector3(0,0,0)
    self._position = Vector3(0,0,0)

    self._highgain = 0
    self._lowgain = 0

    self.audioList = {}
end


---@private
function AudioGroup:__index(k)
    if k == "volume"   then return self._volume   end
    if k == "pitch"    then return self._pitch    end
    if k == "velocity" then return self._velocity end
    if k == "position" then return self._position end
    if k == "highgain" then return self._highgain end
    if k == "lowgain"  then return self._lowgain  end

    return AudioGroup[k]
end


---@private
function AudioGroup:__newindex(k, v)
    if k == "volume"   then self._volume   = v; self:_updateAudioProperties(); return end
    if k == "pitch"    then self._pitch    = v; self:_updateAudioProperties(); return end
    if k == "velocity" then self._velocity = v; self:_updateAudioProperties(); return end
    if k == "position" then self._position = v; self:_updateAudioProperties(); return end
    if k == "highgain" then self._highgain = v; self:_updateAudioProperties(); return end
    if k == "lowgain"  then self._lowgain  = v; self:_updateAudioProperties(); return end

    rawset(self, k, v)
end


---@param ... Audio
function AudioGroup:add(...)
    Lume.push(self.audioList, ...)
end


function AudioGroup:remove(...)
    for i=1, select("#", ...) do
        table.remove(self.audioList, Lume.find(self.audioList, select(i, ...)))
    end
end


function AudioGroup:update(dt)
    for i, audio in ipairs(self.audioList) do
        audio:update(dt)
    end
end


function AudioGroup:play()
    for i, audio in ipairs(self.audioList) do
        audio:play()
    end
end


function AudioGroup:pause()
    for i, audio in ipairs(self.audioList) do
        audio:pause()
    end
end


function AudioGroup:stop()
    for i, audio in ipairs(self.audioList) do
        audio:stop()
    end
end


---@private
function AudioGroup:_updateAudioProperties()
    for _, audio in ipairs(self.audioList) do
        audio:updateBaseProperties(self)
    end
end

return AudioGroup