require "love.image"
require "love.audio"
require "love.event"

local requestChannel = love.thread.getChannel("contentRequest")
local loadData = require "src.engine.resourceHandling._loadContentData"

---@type ContentPromiseRequest
local request = nil

local function setRequestAtomic()
    if requestChannel:getCount() > 0 then
        request = requestChannel:pop()
        return true
    end
    return false
end


while requestChannel:performAtomic(setRequestAtomic) do
    local data = loadData(request)

    request.channel:push(data)
    love.event.push("promiseRequestLoaded", request) ---@diagnostic disable-line param-type-mismatch
end

print("Content loading thread finnished")