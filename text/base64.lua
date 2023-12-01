local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local Base64 = {}

-- https://love2d.org/forums/viewtopic.php?p=219132&sid=4fb67a75845ff84531c4b0c1d06bcff7#p219132
local function byte2bin(n)
    local t = {}
    for i=7,0,-1 do
        t[#t+1] = math.floor(n / 2^i)
        n = n % 2^i
    end
    return table.concat(t)
end

local function text2bin(text)
    local t = {}

    for i=1, #text do
        t[#t+1] = byte2bin(text:byte(i))
    end
    return table.concat(t)
end

-- https://stackoverflow.com/a/37544350
local function bin2number(bin)
    local sum = 0
    bin = bin:reverse()

    for i=1, #bin do
        local num = bin:sub(i, i) == "1" and 1 or 0
        sum = sum + num * (2 ^ (i-1))
    end

    return math.floor(sum)
end

function Base64.encode(text)
    local t = {}

    -- For every 3 chars
    for i = 1, #text, 3 do
        -- Get the binary value of the chars (24 bits)
        local bin = text2bin(text:sub(i, i+2))

        -- For every 6 bits
        for j = 1, #bin, 6 do
            local charBin = bin:sub(j, j+5)

            -- Fill with 0 if there's no enough bits
            charBin = charBin..("0"):rep(6 - #charBin)

            local index = bin2number(charBin) + 1
            t[#t+1] = chars:sub(index, index)
        end
    end

    local result = table.concat(t)
    local padding = #text % 3

    -- Fil the result with "=" if text length is not divisible by 3
    if padding > 0 then
        result = result..("="):rep(3 - padding)
    end

    return result
end

function Base64.decode(text)
    local t = {}

    for i=1, #text, 4 do
        local binList = {}

        for j=0, 3 do
            local char = text:sub(i+j, i+j)

            if char ~= "=" then
                local index = chars:find(char)

                assert(index, "Bad Base64 character \"" .. char .. "\".")

                binList[#binList+1] = byte2bin(index - 1):sub(3)
            end
        end

        local bin = table.concat(binList)

        for j=1, #bin, 8 do
            local charBin = bin:sub(j, j+7)

            if #charBin == 8 then
                local byte = bin2number(charBin)
                t[#t+1] = string.char(byte)
            end

        end
    end

    return table.concat(t)
end

return Base64