local Vector2 = require "engine.math.vector2"
local Object = require "engine.3rdparty.classic.classic"
local Lume = require "engine.3rdparty.lume"
local Textbox = Object:extend("Textbox")

local margin = 10

local patterns = {"%w", "%s", "%p", "%c"}

local function skipAmount(text, pos, skipMultiple, dir)
    local startpos = pos + (dir == -1 and 0 or 1)
    local amount = text[startpos] and 1 or 0

    if skipMultiple and text[startpos] then
        for _, pattern in ipairs(patterns) do
            if text[startpos]:match(pattern) then
                local i = startpos + dir

                while i > 0 and i < #text do
                    if not text[i]:match(pattern) then
                        break
                    end
                    
                    amount = amount + 1
                    i = i + dir
                end
                break
            end
        end
    end

    return amount
end

function Textbox:new(rect)
    self.rect = rect
    self.text = {}
    self.font = love.graphics.getFont()

    self.cursor = 0
    self.cursorBlink = 0
end

function Textbox:_moveCursor(offset)
    self.cursor = Lume.clamp(self.cursor + offset, 0, #self.text+1)
end

function Textbox:draw()
    local pos = self.rect.position
    local size = self.rect.size
    local outPos = pos - margin
    local outSize = size + margin * 2

    love.graphics.print(self.cursor, 0, 40)

    -- Border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", outPos.x, outPos.y, outSize.width, outSize.height)

    -- Draw text
    love.graphics.printf(table.concat(self.text), self.font, pos.x, pos.y, size.width, "left")

    -- Cursor
    if self.cursorBlink < 0.5 then
        local text = ""
        if self.text[self.cursor] then
            text = table.concat(self.text, "", 1, self.cursor)
        end
        local _, wrapped = self.font:getWrap(text, size.width)
        local fontHeight = self.font:getHeight()
        local cursorPos = pos + Vector2(self.font:getWidth(wrapped[#wrapped]), #wrapped * fontHeight)

        love.graphics.line(cursorPos.x, cursorPos.y, cursorPos.x, cursorPos.y - fontHeight)
    end
end

function Textbox:update(dt)
    self.cursorBlink = (self.cursorBlink + dt) % 1
end

function Textbox:textinput(t)
    self:_moveCursor(1)
    table.insert(self.text, self.cursor, t)

    self.cursorBlink = 0
end

function Textbox:keypressed(k)
    local ctrlDown = love.keyboard.isDown("lctrl")
    local skipBefore = skipAmount(self.text, self.cursor, ctrlDown, -1)
    local skipNext = skipAmount(self.text, self.cursor, ctrlDown, 1)

    print("Skip before", skipBefore, "\nSkip next", skipNext)

    if k == "backspace" and self.cursor > 0 then
        self:_moveCursor(-skipBefore)
        self.cursorBlink = 0
        
        for i=1, skipBefore do
            table.remove(self.text, self.cursor+1)
        end
    end
    
    if k == "delete" and self.cursor < #self.text then
        for i=1, skipNext do
            table.remove(self.text, self.cursor+1)
        end
        self.cursorBlink = 0
    end
    
    if k == "left" then
        self:_moveCursor(-skipBefore)
        self.cursorBlink = 0
    end
    
    if k == "right" then
        self:_moveCursor(skipNext)
        self.cursorBlink = 0
    end

    if k == "home" then
        self.cursor = 0
        self.cursorBlink = 0
    end

    if k == "end" then
        self.cursor = #self.text
        self.cursorBlink = 0
    end
end


return Textbox