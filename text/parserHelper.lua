local Object = require "engine.3rdparty.classic.classic"

--- @class ParserHelper: Object
---
--- @field public text string
--- @field public pos integer
--- @field private autoSkipWhitespaces boolean
---
--- @field public WhitespacePattern string
--- @field public AlphanumericPattern string
--- @field public IdentifierPattern string
---
--- @overload fun(text: string?, autoSkipWhitespaces: boolean?): ParserHelper
local Parser = Object:extend("ParserHelper")


Parser.WhitespacePattern = "%s*"
Parser.AlphanumericPattern = "%w*"
Parser.IdentifierPattern = "%a+[%w_]*"
Parser.NumberPattern = "%d*%.?%d+"


function Parser:new(text, autoSkipWhitespaces)
    self.text = nil
    self.pos = 1
    self.autoSkipWhitespaces = autoSkipWhitespaces or false
    self:reset(text or "")
end


---@param text string
---@return ParserHelper
function Parser:reset(text)
    self.text = text
    self.pos = 1
    return self
end


---@param steps integer
---@return ParserHelper
function Parser:jump(steps)
    self.pos = self.pos + steps
    return self
end


---@param range integer
---@return string
function Parser:peek(range)
    return self.text:sub(self.pos, self.pos + (range-1))
end


---@return ParserHelper
function Parser:skipWhitespaces()
    self.pos = self.pos + #(self.text:match("^"..Parser.WhitespacePattern, self.pos))
    return self
end


---@param char string
---@return string?
function Parser:eat(char)
    if self.autoSkipWhitespaces then
        self:skipWhitespaces()
    end
    local len = #char

    if self:peek(len) == char then
        self.pos = self.pos + len
        return char
    end
    return nil
end


---@param pattern string
---@return string?
function Parser:eatMatch(pattern)
    if self.autoSkipWhitespaces then
        self:skipWhitespaces()
    end
    local match = self.text:match("^"..pattern, self.pos)

    if match then
        self.pos = self.pos + #match
        return match
    end
    return nil
end


---@return boolean
function Parser:isEOF()
    return self.pos > #self.text
end


return Parser