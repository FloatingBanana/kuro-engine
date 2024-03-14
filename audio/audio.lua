local Object  = require "engine.3rdparty.classic.classic"
local Vector3 = require "engine.math.vector3"
local Vector2 = require "engine.math.vector2"
local Timer = require "engine.misc.timer"
local Lume = require "engine.3rdparty.lume"
local Utils = require "engine.misc.utils"


---@class Audio: Object
---
---@field public source love.Source
---
---@field public multiSource boolean
---@field public volume number
---@field public pitch number
---@field public position Vector3
---@field public velocity Vector3
---@field public direction Vector3
---@field public attenuationDistances Vector2
---@field public volumeLimits Vector2
---@field public currentSecond number
---@field public currentSample integer
---@field public airAbsorption number
---@field public rollof number
---@field public isPlaying boolean
---@field public loop boolean
---@field public absoluteVolume number
---@field public absolutePitch number
---@field public absolutePosition Vector3
---@field public absoluteVelocity Vector3
---@field public enableFilter boolean
---@field public filter "lowpass"|"highpass"|"bandpass"
---@field public lowgain number
---@field public highgain number
---
---@field private _volume number
---@field private _pitch number
---@field private _position Vector3
---@field private _velocity Vector3
---@field private _baseVolume number
---@field private _basePitch number
---@field private _basePosition Vector3
---@field private _baseVelocity Vector3
---
---@overload fun(path: string|love.SoundData|love.Decoder|love.FileData|love.File, type: love.SourceType): Audio
---@overload fun(source: love.Source): Audio
local Audio = Object:extend("Audio")

function Audio:new(source, type)
    if Utils.getType(source) == "Source" then
        self.source = source
    else
        self.source = love.audio.newSource(source, type)
    end

    self.multiSource = true

    self._baseVolume = self.source:getVolume()
    self._basePitch = self.source:getPitch()
    self._basePosition = Vector3(0)
    self._baseVelocity = Vector3(0)
    self._baseHighgain = 1
    self._baseLowgain = 1

    self._volume = self.source:getVolume()
    self._pitch = self.source:getPitch()
    self._position = Vector3(0)
    self._velocity = Vector3(0)
    self._filter = {type = "lowpass", lowgain = 1, highgain = 1}


    self._fadeInTimer = Timer(0, 0, false)
    self._fadeOutTimer = Timer(0, 0, false)

    self._fadeInTimer.onEndedEvent:addCallback(function() self.volume = self.volume end)
    self._fadeOutTimer.onEndedEvent:addCallback(function() self:stop(); self.volume = self.volume end)
end

function Audio:__index(k)
    if k == "volume"               then return self._volume end
    if k == "pitch"                then return self._pitch end
    if k == "position"             then return self._position end
    if k == "velocity"             then return self._velocity end
    if k == "direction"            then return Vector3(self.source:getDirection()) end
    if k == "attenuationDistances" then return Vector2(self.source:getAttenuationDistances()) end
    if k == "volumeLimits"         then return Vector2(self.source:getVolumeLimits()) end
    if k == "currentSecond"        then return self.source:tell("seconds") end
    if k == "currentSample"        then return self.source:tell("samples") end
    if k == "airAbsorption"        then return self.source:getAirAbsorption() end
    if k == "rollof"               then return self.source:getRolloff() end
    if k == "isPlaying"            then return self.source:isPlaying() end
    if k == "loop"                 then return self.source:isLooping() end

    if k == "enableFilter"         then return self.source:getFilter() ~= nil end
    if k == "filter"               then return self._filter.type end
    if k == "highgain"             then return self._filter.highgain end
    if k == "lowgain"              then return self._filter.lowgain end

    if k == "absoluteVolume"       then return self._volume * self._baseVolume end
    if k == "absolutePitch"        then return self._pitch * self._basePitch end
    if k == "absolutePosition"     then return self._position + self._basePosition end
    if k == "absoluteVelocity"     then return self._velocity + self._baseVelocity end

    return Audio[k]
end

function Audio:__newindex(k, v)
    if k == "volume"               then self._volume   = v; self.source:setVolume(self.absoluteVolume); return end
    if k == "pitch"                then self._pitch    = v; self.source:setPitch(self.absolutePitch); return end
    if k == "position"             then self._position = v; self.source:setPosition(self.absolutePosition:split()); return end
    if k == "velocity"             then self._velocity = v; self.source:setVelocity(self.absoluteVelocity:split()); return end
    if k == "direction"            then self.source:setDirection(v.x, v.y, v.z); return end
    if k == "attenuationDistances" then self.source:setAttenuationDistances(v.min, v.max); return end
    if k == "volumeLimits"         then self.source:setVolumeLimits(v.min, v.max); return end
    if k == "currentSecond"        then self.source:seek(v, "seconds"); return end
    if k == "currentSample"        then self.source:seek(v, "samples"); return end
    if k == "airAbsorption"        then self.source:setAirAbsorption(v); return end
    if k == "rollof"               then self.source:setRolloff(v); return end
    if k == "isPlaying"            then if v then self.source:play() else self.source:pause() end; return end
    if k == "loop"                 then self.source:setLooping(v); return end

    if k == "enableFilter"         then self.source:setFilter(v and self._filter or nil); return end
    if k == "filter"               then self._filter.type     = v; self.source:setFilter(self.enableFilter and self._filter or nil); return end
    if k == "highgain"             then self._filter.highgain = v; self.source:setFilter(self.enableFilter and self._filter or nil); return end
    if k == "lowgain"              then self._filter.lowgain  = v; self.source:setFilter(self.enableFilter and self._filter or nil); return end

    if k == "absoluteVolume"       then self.volume   = v / self._baseVolume; return end
    if k == "absolutePitch"        then self.pitch    = v / self._basePitch; return end
    if k == "absolutePosition"     then self.position = v - self._basePosition; return end
    if k == "absoluteVelocity"     then self.velocity = v - self._baseVelocity; return end

    rawset(self, k, v)
end


---@param group AudioGroup?
function Audio:updateBaseProperties(group)
    self._baseVolume   = group and group.volume or 1
    self._basePitch    = group and group.pitch or 1
    self._basePosition = group and group.position or Vector3(0,0,0)
    self._baseVelocity = group and group.velocity or Vector3(0,0,0)
    self._baseHighgain = group and group.highgain or 1
    self._baseLowgain  = group and group.lowgain or 1

    -- Trigger metamethods
    self.volume   = self._volume
    self.pitch    = self._pitch

    if self.source:getChannelCount() == 1 then
        self.position = self._position
        self.velocity = self._velocity
    end

    self.enableFilter = self.enableFilter
end


function Audio:update(dt)
    if self._fadeInTimer:update(dt).running then
        local t = self._fadeInTimer.progress
        self.source:setVolume(Lume.lerp(0, self.volume, t))
    end

    if self._fadeOutTimer:update(dt).running then
        local t = self._fadeOutTimer.progress
        self.source:setVolume(Lume.lerp(self.volume, 0, t))
    end
end


---@param fade number
---@return Audio
---@overload fun(): Audio
function Audio:play(fade)
    if fade and fade > 0 then
        self._fadeInTimer.duration = fade
        self._fadeInTimer:restart():play()
    end

    if self.multiSource then
        self.source:clone():play()
    else
        self.source:play()
    end
    return self
end


function Audio:stop(fade)
    if fade and fade > 0 then
        self._fadeOutTimer.duration = fade
        self._fadeOutTimer:restart():play()
    else
        self.source:stop()
    end
end


---@param innerAngle number
---@param outerAngle number
---@param outerVolume number
---@return Audio
---@overload fun(): number, number, number
function Audio:cone(innerAngle, outerAngle, outerVolume)
    if innerAngle or outerAngle or outerVolume then
        self.source:setCone(innerAngle, outerAngle, outerVolume)
        return self
    end
    return self.source:getCone()
end

return Audio