local layerFuncs = {}


local function recursive_search(t, key, value, unique, recursive)
    local layers = nil

    if not unique then
        layers = {}
    end

    for i, layer in ipairs(t) do
        if layer[key] == value then
            if unique then
                return layer
            else
                layers[#layers+1] = layer
            end
        end

        if recursive and layer.type == "group" then
            local nLayers = recursive_search(layer.layers, key, value, unique, true)

            if unique then
                if nLayers then
                    return nLayers
                end
            else
                for _, nested in ipairs(nLayers) do
                    layers[#layers+1] = nested
                end
            end
        end
    end

    return layers
end

function layerFuncs:getAllLayers(recursive)
    recursive_search(self.layers, "_", nil, false, recursive)
end

function layerFuncs:getLayerByName(name, unique, recursive)
    return recursive_search(self.layers, "name", name, unique, recursive)
end

function layerFuncs:getLayerById(id, recursive)
    return recursive_search(self.layers, "id", id, true, recursive)
end

function layerFuncs:getLayerByType(layerType, unique, recursive)
    return recursive_search(self.layers, "type", layerType, unique, recursive)
end

return layerFuncs