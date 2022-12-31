local csv = {}

local text = ""
local pos = 1

local function current()
    return text:sub(pos, pos)
end

local function isEOF()
    return pos > #text
end

function csv.parse(csvtext)
    text = csvtext
    pos = 1

    local elements = {}
    local start = pos

    while not isEOF() do
        pos = pos + 1

        if current() == "," or isEOF() then
            local value = nil

            if pos > start then
                value = text:sub(start, pos-1)
            elseif pos == start then
                value = ""
            end

            elements[#elements+1] = value
            start = pos + 1
        end

        if current() == "\'" or current() == "\"" then
            local quote = current()

            repeat
                pos = pos + 1
                assert(not isEOF(), "unmatched quote")
            until current() == quote
        end
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