local Stack = require "engine.collections.stack"
local XML = {}

local whitespacePattern = "[\n\r%s]*"
local alphanumericPattern = "[a-zA-Z0-9]*"

local pos = 1
local text = ""

local function current()
    return text:sub(pos, pos)
end

local function eat(char)
    local endPos = pos + #char-1

    if text:sub(pos, endPos) == char then
        pos = endPos+1
        return char
    end
    return nil
end

local function eatMatch(pattern)
    local match = text:match("^"..pattern, pos)

    if match then
        pos = pos + #match
        return match
    end
    return nil
end

local function isEOF()
    return pos > #text
end

local function trimText(txt)
    return txt:gsub("^"..whitespacePattern, ""):gsub(whitespacePattern.."$", "")
end

local function parse()
    if eat("<") then
        if eat("!") then
            -- Comment
            if eat("--") then
                while not eat("-->") do
                    pos = pos+1
                end
                return nil
            end

            -- CDATA
            if eat("[CDATA[") then
                local startPos = pos
                local endPos = pos

                while not eat("]]>") do
                    pos = pos+1
                    endPos = endPos+1

                    assert(not isEOF(), "missing ']]>'")
                end

                local value = trimText(text:sub(startPos, endPos-1))
                if startPos < endPos and value ~= "" then
                    return {
                        type = "text",
                        value = value
                    }
                end

                return nil
            end
        end

        -- Closing tag
        if eat("/") then
            local name = eatMatch(alphanumericPattern)
            assert(name, "invalid element name")

            eatMatch(whitespacePattern)

            if not eat(">") then
                error("closing brace expected")
            end

            return {
                type = "close_tag",
                name = name,
            }
        end

        eat("?")

        local element = {
            type = "open_tag",
            name = eatMatch(alphanumericPattern),
            value = nil,
            properties = {}
        }
        assert(element.name, "invalid element name")

        -- Properties
        while true do
            assert(not isEOF(), "missing '>'")

            eatMatch(whitespacePattern)

            if eat("/>") or eat("?>") then
                element.type = "single_element"
                break
            end

            if eat(">") or eat("?>") then
                break
            end

            local propName = eatMatch(alphanumericPattern)
            assert(propName, "invalid property name")

            eatMatch(whitespacePattern)

            if eat("=") then
                eatMatch(whitespacePattern)

                local quote = eat("\"") or eat("\'")
                assert(quote, "invalid property")

                local value = eatMatch("(.-)"..quote)
                assert(value, "invalid property")
                eat(quote)

                element.properties[propName] = value
            else
                error("= symbol expected")
            end
        end

        return element
    end

    local start = pos
    while not isEOF() and current() ~= "<" do
        pos = pos+1
    end

    local value = trimText(text:sub(start, pos-1))

    if value == "" then
        return nil
    end

    value = value:gsub("&lt;", "<")
                 :gsub("&gt;", ">")
                 :gsub("&quot;", "\"")
                 :gsub("&apos;", "\'")
                 :gsub("&amp;", "&")

    return {
        type = "text",
        value = value
    }
end

function XML.decode(xmltext)
    pos = 1
    text = xmltext

    local elmStack = Stack()

    elmStack:push({
        name = "root",
        children = {}
    })

    while not isEOF() do
        local parent = elmStack:peek()
        local token = parse()

        if token then
            if token.type == "open_tag" then
                local elm = {
                    name = token.name,
                    properties = token.properties,
                    children = {}
                }

                table.insert(parent.children, elm)
                elmStack:push(elm)
            end

            if token.type == "close_tag" then
                assert(token.name == parent.name, "missing closing tag for '"..parent.name.."'")
                elmStack:pop()
            end

            if token.type == "single_element" then
                local elm = {
                    name = token.name,
                    properties = token.properties,
                }

                table.insert(parent.children, elm)
            end

            if token.type == "text" then
                table.insert(parent.children, token.value)
            end
        end
    end

    local root = elmStack:pop()
    assert(root.name == "root", "missing closing tag for '"..root.name.."'")

    return root.children
end

function XML.encode(t, minimal, identLevel)
    local result = Stack()
    identLevel = identLevel or 0

    for i, elm in pairs(t) do
        local ident = ("\t"):rep(minimal and 0 or identLevel)
        result:push(ident)

        -- Text element
        if type(elm) == "string" then
            result:push(elm)

            if not minimal then result:push("\n") end
        else
            result:push("<")
            result:push(elm.name)

            if elm.properties then
                for key, value in pairs(elm.properties) do
                    local prop = (" %s=\"%s\""):format(key, value)
                    result:push(prop)
                end
            end

            if elm.children then
                result:push(">")
                if not minimal then result:push("\n") end

                local child = XML.encode(elm.children, minimal, identLevel+1)
                result:push(child)

                local closeTag = ("</%s>"):format(elm.name)
                result:push(ident)
                result:push(closeTag)
            else
                -- Single element
                result:push("/>")
                if not minimal then result:push("\n") end
            end
        end
    end

    return table.concat(result)
end

return XML