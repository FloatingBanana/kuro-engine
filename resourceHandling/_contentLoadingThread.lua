require "love.image"
require "love.audio"
require "love.event"
require "love.timer"

local id = ...
print("Content loading thread started. ID: "..id)

local requestChannel = love.thread.getChannel("contentRequest")
local loadData = require "engine.resourceHandling._loadContentData"

local THREAD_LIFETIME = 3
local initTime = love.timer.getTime()


while (love.timer.getTime() - initTime) < THREAD_LIFETIME do
    local request = requestChannel:pop() --[[@as ContentPromiseRequest]]

    if request then
        local response = loadData(request)
        initTime = love.timer.getTime()

        love.event.push("promiseRequestLoaded", request, response) ---@diagnostic disable-line param-type-mismatch

        print("Thread "..id..": finished loading promise: "..request.filepath)
    end
end

print("Content loading thread finnished. ID: "..id)