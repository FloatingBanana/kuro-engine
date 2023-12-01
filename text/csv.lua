local ParserHelper = require "engine.misc.parserHelper"
local csv = {}

function csv.parse(csvtext)
    local parser = ParserHelper(csvtext)
    local elements = {}

    local startPos = 1
    local endPos = 1

    while true do
        if parser:eat(",") or parser:isEOF() then
            local value = ""

            if startPos < endPos then
                value = csvtext:sub(startPos, endPos-1)
            end

            elements[#elements+1] = value
            startPos = parser.pos

            if parser:isEOF() then
                break
            end
        else
            local quote = parser:eat("\"") or parser:eat("\'")
            if quote then
                local escape = false

                while not (parser:eat(quote) and not escape) do
                    escape = (parser:peek(1) == "\\")

                    assert(not parser:isEOF(), "unmatched quote")
                    parser:jump(1)
                end
            else
                parser:jump(1)
            end
        end

        endPos = parser.pos
    end

    return elements
end

function csv.parseTable(csvtext)
    local list = {}

    for line in csvtext:gmatch("[^\r\n]+") do
        list[#list+1] = csv.parse(line)
    end

    return list
end

return csv