local Parser = Object:extend()

Parser.whitespacePattern = "[\n\r%s]*"
Parser.alphanumericPattern = "[a-zA-Z0-9]*"
Parser.identifierPattern = "[a-zA-Z0-9_]*"

function Parser:new(text)
    self:reset(text)
end

function Parser:reset(text)
    self.text = text
    self.pos = 1
end

function Parser:jump(steps)
    self.pos = self.pos + steps
end

function Parser:back(steps)
    self.pos = self.pos - steps
end

function Parser:peek(range)
    return self.text:sub(self.pos, self.pos + (range-1))
end

function Parser:eat(char, skipWhitespace)
    if skipWhitespace then
        self:eatMatch(Parser.whitespacePattern, false)
    end
    local endPos = self.pos + #char-1

    if self.text:sub(self.pos, endPos) == char then
        self.pos = endPos+1
        return char
    end
    return nil
end

function Parser:eatMatch(pattern, skipWhitespace)
    if skipWhitespace then
        self:eatMatch(Parser.whitespacePattern, false)
    end
    local match = self.text:match("^"..pattern, self.pos)

    if match then
        self.pos = self.pos + #match
        return match
    end
    return nil
end

function Parser:isEOF()
    return self.pos > #self.text
end

return Parser