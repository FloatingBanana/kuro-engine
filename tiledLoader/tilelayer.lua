local tilelayer = {}

function tilelayer:isCSV()
    assert(self.encoding == "lua", "The map format must be CSV. Current format: "..self.encoding.." ("..(self.compression or "uncompressed")..")")
end

function tilelayer:getIndex(col, row)
    return ((col - 1) % self.width + 1) + (row-1) * self.width
end

function tilelayer:getCell(index)
    local i = index - 1

    local col = (i % self.width)
    local row = math.floor(i / self.width)

    return col,  row
end

function tilelayer:getPosition(col, row)
    local x = col * self._root.tilewidth
    local y = row * self._root.tileheight

    return x, y
end

function tilelayer:getTargetTilesetTile(tile)
    for i, set in ipairs(self._root.tilesets) do
        if set.firstgid <= tile + 1 and set.firstgid + set.tilecount > tile + 1 then
            return tile - set.firstgid + 1, set
        end
    end
    return -1, nil
end

function tilelayer:getTile(col, row)
    self:isCSV()

    return self.data[self:getIndex(col, row)] - 1
end

function tilelayer:iterate()
    self:isCSV()

    local size = #self.data
    local i = 0

    return function()
        if i < size then
            i = i+1

            local col, row = self:getCell(i)
            return col, row, self:getTargetTilesetTile(self.data[i] - 1)
        end

        return nil
    end
end

function tilelayer:iteratePosition()
    self:isCSV()

    local size = #self.data
    local i = 0

    return function()
        if i < size then
            i = i+1

            local x, y = self:getPosition(self:getCell(i))
            return x, y, self:getTargetTilesetTile(self.data[i] - 1)
        end

        return nil
    end
end

return tilelayer