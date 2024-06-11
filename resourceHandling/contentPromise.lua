local Object = require "engine.3rdparty.classic.classic"
local Event  = require "engine.misc.event"
local loadData = require "src.engine.resourceHandling._loadContentData"

local requestChannel = love.thread.getChannel("contentRequest")

local allPromises = setmetatable({}, {__mode = 'v'})
local threads = {}

for i=1, math.min(love.system.getProcessorCount(), 4) do
    threads[i] = love.thread.newThread("engine/resourceHandling/_contentLoadingThread.lua")
end


local function defaultErrorHandler(promise, message)
    error("Failed to load content: "..message)
end


---@alias ContentPromiseRequest {filepath: string, hint: ContentTypeHint, args: table}
---@alias ContentPromiseResponse {success: boolean, value: any}
---@alias ContentPromiseErrorHandler fun(promise: ContentPromise, message: string)

---@class ContentPromise: Object
---
---@field public content any
---@field public isLoading boolean
---@field public onCompleteEvent Event
---@field private _errorHandler ContentPromiseErrorHandler
---@field private _request ContentPromiseRequest
---
---@overload fun(file: string, hint: ContentTypeHint, ...): ContentPromise
local ContentPromise = Object:extend("ContentPromise")

function ContentPromise:new(file, hint, ...)
    self.content = nil
    self.isLoading = false
    self.onCompleteEvent = Event()

    self._errorHandler = defaultErrorHandler
    self._request = {filepath = file, hint = hint, args = {...}}

    allPromises[file] = self
end



---@private
---@param response ContentPromiseResponse
function ContentPromise:_finishLoading(response)
    if not self.isLoading then
        print("promise content discarted: "..self._request.filepath)

    elseif response.success then
        if self._request.hint == "image" then
            self.content = love.graphics.newImage(response.value, self._request.args[1])
        end

        self.onCompleteEvent:trigger(self)
    else
        self._errorHandler(self, response.value)
    end

    self.isLoading = false
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
        self.isLoading = true
        self:_finishLoading(loadData(self._request))
    end
    return self
end



---@return self
function ContentPromise:unload()
    self.content = nil
    self.isLoading = false
    return self
end



---@param func ContentPromiseErrorHandler
---@return self
function ContentPromise:setErrorHandler(func)
    self._errorHandler = func
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

    for i, thread in ipairs(threads) do
        thread:wait()
    end
end


---@diagnostic disable-next-line undefined-field
function love.handlers.promiseRequestLoaded(request, response)
    local promise = allPromises[request.filepath]
    assert(promise)

    promise:_finishLoading(response)
end



return ContentPromise