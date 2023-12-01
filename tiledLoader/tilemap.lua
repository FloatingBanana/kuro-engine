local tilesets = {}

function tilesets:getTilesetByTile(tile)
    for i, tileset in ipairs(self.tilesets) do
        if tile >= tileset.firstgrid and tile < tileset.firstgrid + tileset.tilecount then
            return tileset
        end
    end
end

return tilesets