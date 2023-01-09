local tiled = {}

local tilelayer = require("engine.tiledloader.tilelayer")
local objectlayer = require("engine.tiledloader.objectlayer")
local layerFuncs = require("engine.tiledloader.layers")

local tmxLoader = require "engine.tiledLoader.tmx_loader"

local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

local function set_layer_methods(t, obj)
    for i, layer in ipairs(t) do
        if layer.type == "tilelayer" then
            merge_tables(layer, tilelayer)
        end

        if layer.type == "objectgroup" then
            merge_tables(layer, objectlayer)
        end

        if layer.type == "group" then
            merge_tables(layer, layerFuncs)
            set_layer_methods(layer.layers, obj)
        end

        layer._root = obj
    end
end



function tiled.loadTable(t)
    set_layer_methods(t.layers, t)
    merge_tables(t, layerFuncs)

    return t
end

function tiled.loadTmx(file)
    local xml, err = lfs.read(file)
    assert(xml, ("Could not open %s: %s"):format(file, err))

    local obj = tmxLoader(xml)

    set_layer_methods(obj.layers, obj)
    merge_tables(obj, layerFuncs)

    return obj
end


return tiled