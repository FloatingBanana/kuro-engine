local xml = require "engine.text.xml"
local csv = require "engine.text.csv"
local base64 = require "engine.textc.base64"

local layer_types = {layer = true, objectgroup = true, group = true, imagelayer = true}
local shape_types = {ellipse = true, point = true, polygon = true, polyline = true}

local get_layer = nil

local function get_properties(elm)
    local properties = {}

    for _, prop in pairs(elm.children) do
        if prop.name == "property" then
            local props = prop.properties
            local val = nil

            if props.type == "bool" then
                val = props.value == "true"
            elseif props.type == "int" or props.type == "float" then
                val = tonumber(props.value)
            else
                val = props.value
            end

            properties[props.name] = val
        end
    end

    return properties
end

local function get_tileset(element)
    local props = element.properties
    local tileset = {
        name            = props.name,
        firstgid       = tonumber(props.firstgid),
        class           = "", -- TODO
        tilewidth       = tonumber(props.tilewidth),
        tileheight      = tonumber(props.tileheight),
        spacing         = tonumber(props.spacing or 0),
        margin          = tonumber(props.margin or 0),
        columns         = tonumber(props.columns),
        tilecount       = tonumber(props.tilecount),
        objectalignment = props.objectalignment or "unspecified",
        tilerendersize  = props.tilerendersize or "tile",
        fillmode        = props.fillmode or "stretch",
        properties      = {}, -- TODO
        wangsets        = {}, -- TODO
        tiles           = {}, -- TODO
        tileoffset = { -- TODO
            x = 0,
            y = 0
        },
        grid = {
            orientation = "orthogonal", -- TODO
            width = props.tilewidth,
            height = props.tileheight,
        },
    }

    local propertiesElm = Lume.filter(element.children, function(elm) return elm.name == "properties" end)[1]
    tileset.properties = propertiesElm and get_properties(propertiesElm) or {}

    local imageElm = Lume.filter(element.children, function(elm) return elm.name == "image" end)[1]
    local imageProps = imageElm.properties
    tileset.image = imageProps.source
    tileset.imagewidth = imageProps.width
    tileset.imageheight = imageProps.height

    return tileset
end

local function process_tilemap_layer(layer, element)
    local dataElm = Lume.filter(element.children, function(elm) return elm.name == "data" end)[1]
    local csvdata = csv.parse(dataElm.children[1])
    local encoding = dataElm.properties.encoding

    layer.type = "tilelayer"
    layer.encoding = (encoding == "csv" and "lua" or encoding)
    layer.data = Lume.map(csvdata, tonumber)
end

local function process_objectgroup_layer(layer, element)
    layer.draworder = element.properties.draworder or "topdown"
    layer.objects = {}

    for i, objectElm in ipairs(element.children) do
        local props = objectElm.properties

        local object = {
            id         = tonumber(props.id),
            name       = props.name or "",
            type       = props.type or "",
            shape      = "rectangle",
            x          = tonumber(props.x),
            y          = tonumber(props.y),
            width      = tonumber(props.width or 0),
            height     = tonumber(props.height or 0),
            rotation   = tonumber(props.rotation or 0),
            visible    = not props.visible or props.visible == 1,
            properties = {}
        }

        for _, child in ipairs(objectElm.children or {}) do
            if shape_types[child.name] then
                object.shape = child.name
            end

            if child.name == "polyline" or child.name == "polygon" then
                local points = {}

                for pos in child.props.points:gmatch("[^%s]+") do
                    local point = pos:gmatch("[^,]+")

                    table.insert(point, {
                        x = tonumber(point()),
                        y = tonumber(point())
                    })
                end

                object[child.name] = points
            end

            if child.name == "properties" then
                object.properties = get_properties(child)
            end
        end

        table.insert(layer.objects, object)
    end
end

local function process_group_layer(layer, layerElm)
    layer.layers = {}

    for i, child in ipairs(layerElm.children) do
        layer.layers[i] = get_layer(child)
    end
end

local function process_image_layer(layer, layerElm)
    local imageElm = Lume.filter(layerElm.children, function(child) return child.name == "image" end)[1]

    layer.image = imageElm.properties.source
end

get_layer = function(layerElm)
    local layerType = layerElm.name
    local props = layerElm.properties
    local layer = {
        type       = layerType,
        x          = 0,
        y          = 0,
        width      = tonumber(props.width),
        height     = tonumber(props.height),
        id         = tonumber(props.id),
        name       = props.name,
        visible    = not props.visible or props.visible == 1,
        opacity    = tonumber(props.opacity or 1),
        offsetx    = tonumber(props.offsetx or 0),
        offsety    = tonumber(props.offsety or 0),
        parallaxx  = tonumber(props.parallaxx or 1),
        parallaxy  = tonumber(props.parallaxy or 1),
        properties = {}
    }

    if layerType == "layer" then
        process_tilemap_layer(layer, layerElm)
    end

    if layerType == "objectgroup" then
        process_objectgroup_layer(layer, layerElm)
    end

    if layerType == "group" then
        process_group_layer(layer, layerElm)
    end

    if layerType == "image" then
        process_image_layer(layer, layerElm)
    end

    local propertiesElm = Lume.filter(layerElm.children, function(elm) return elm.name == "properties" end)[1]
    layer.properties = propertiesElm and get_properties(propertiesElm) or {}

    return layer
end

local function tmxLoader(code)
    local tmx = xml.decode(code)
    local map = tmx[2]

    local result = {
        version      = map.properties.version,
        luaversion   = "5.1",
        tiledversion = map.properties.tiledversion,
        class        = "", -- TODO
        orientation  = map.properties.orientation,
        renderorder  = map.properties.renderorder,
        infinite     = map.properties.infinite == "1",
        width        = tonumber(map.properties.width),
        height       = tonumber(map.properties.height),
        tilewidth    = tonumber(map.properties.tilewidth),
        tileheight   = tonumber(map.properties.tileheight),
        nextlayerid  = tonumber(map.properties.nextlayerid),
        nextobjectid = tonumber(map.properties.nextobjectid),

        properties = {},
        tilesets = {},
        layers = {},
    }

    for _, elm in ipairs(map.children) do
        -- Map properties
        if elm.name == "properties" then
            result.properties = get_properties(elm)
        end

        -- Tilesets
        if elm.name == "tileset" then
            table.insert(result.tilesets, get_tileset(elm))
        end

        -- Layers
        if layer_types[elm.name] then
            table.insert(result.layers, get_layer(elm))
        end
    end

    return result
end

return tmxLoader