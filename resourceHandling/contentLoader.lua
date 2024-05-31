local Object = require "engine.3rdparty.classic.classic"
local ContentPromise = require "engine.resourceHandling.contentPromise"


---@alias ContentTypeHint "image"|"imagedata"|"source"

---@class ContentLoader: Object
---
---@field private promises table<string, ContentPromise>
---
---@overload fun(): self
local ContentLoader = Object:extend("ContentLoader")


function ContentLoader:new()
    self.promises = {}
end



---@param filename string
---@param hint ContentTypeHint
---@param ... unknown
---@return ContentPromise
function ContentLoader:getContent(filename, hint, ...)
    local promise = self.promises[filename]

    if not promise then
        promise = ContentPromise(filename, hint, ...)
        self.promises[filename] = promise
    end

    return promise
end



---@param filename string
---@param settings table
---@return ContentPromise
function ContentLoader:getImage(filename, settings)
    return self:getContent(filename, "image", settings)
end



---@param filename string
---@return ContentPromise
function ContentLoader:getImageData(filename)
    return self:getContent(filename, "imagedata")
end



---@param filename string
---@param type love.SourceType
---@return ContentPromise
function ContentLoader:getSource(filename, type)
    return self:getContent(filename, "image", type)
end



---@return self
function ContentLoader:unloadAll()
    for filename, promise in pairs(self.promises) do
        promise:unload()
        self.promises[filename] = nil
    end
    return self
end



---@param loader ContentLoader
---@return self
function ContentLoader:merge(loader)
    for filename, promise in pairs(loader.promises) do
        self.promises[filename] = promise
        loader.promises[filename] = nil
    end
    return self
end



return ContentLoader