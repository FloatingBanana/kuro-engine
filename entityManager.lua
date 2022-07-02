local EM = {
    entities = {}
}

function EM.add(entity)
    EM.entities[entity] = true;
end

function EM.emit(funcname, ...)
    for entity in pairs(EM.entities) do
        entity[funcname](entity, ...)
    end
end

function EM.remove(entity)
    EM.entities[entity] = nil
end

function EM.exist(entity)
    return not not EM.entities[entity]
end

function EM.clear()
    for entity in pairs(EM.entities) do
        EM.remove(entity)
    end
end

return EM