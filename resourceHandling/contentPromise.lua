local Object = require "engine.3rdparty.classic.classic"
local Event  = require "engine.misc.event"
local loadData = require "src.engine.resourceHandling._loadContentData"

local requestChannel = love.thread.getChannel("contentRequest")

local allPromises = setmetatable({}, {__mode = 'v'})
local threads = {}

for i=1, love.system.getProcessorCount() do
    threads[i] = love.thread.newThread("engine/resourceHandling/_contentLoadingThread.lua")
end


---@alias ContentPromiseRequest {filepath: string, hint: ContentTypeHint, channel: love.Channel, args: table}

---@class ContentPromise: Object
---
---@field public content any
---@field public isLoading boolean
---@field public onCompleteEvent Event
---@field private _channel love.Channel
---@field private _request ContentPromiseRequest
---
---@overload fun(file: string, hint: ContentTypeHint, ...): ContentPromise
local ContentPromise = Object:extend("ContentPromise")

function ContentPromise:new(file, hint, ...)
    self.content = nil
    self.isLoading = false
    self.onCompleteEvent = Event()

    self._channel = love.thread.newChannel()
    self._request = {filepath = file, hint = hint, channel = self._channel, args = {...}}

    allPromises[file] = self
end



---@private
---@param content any
function ContentPromise:_finishLoading(content)
    if self._request.hint == "image" then
        self.content = love.graphics.newImage(content, self._request.args[1])
    end

    self.isLoading = false
    self.onCompleteEvent:trigger(self)
end



---@return self
function ContentPromise:loadAsync()
    if not self.isLoading and not self.content then
        requestChannel:push(self._request)
        ContentPromise.UpdateThreads()

        self.isLoading = true
    end
    return self
end



---@return self
function ContentPromise:load()
    if not self.content then
        self:_finishLoading(loadData(self._request))
    end
    return self
end



---@return self
function ContentPromise:update()
    if self._channel:getCount() > 0 then
        local content = self._channel:pop()

        if self.isLoading then
            self:_finishLoading(content)
        else
            print("promise content discarted: "..self._request.filepath)
            self.isLoading = false
        end
    end
    return self
end



---@return self
function ContentPromise:unload()
    self.content = nil
    self.isLoading = false
    return self
end






function ContentPromise.UpdateThreads()
    for i, thread in ipairs(threads) do
        if not thread:isRunning() and requestChannel:getCount() > 0 then
            thread:start(i)
        end
    end
end


function ContentPromise.Quit()
    requestChannel:clear()

    for _, promise in pairs(allPromises) do
        promise._request.channel:clear()
    end

    for i, thread in ipairs(threads) do
        thread:wait()
    end
end


---@diagnostic disable-next-line undefined-field
function love.handlers.promiseRequestLoaded(request)
    local promise = allPromises[request.filepath]
    assert(promise)

    promise:update()
end



return ContentPromise