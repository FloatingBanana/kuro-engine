local CM = {
    entities = {} ---@type table<Entity, boolean>
}


---@param entity Entity
function CM.addEntity(entity)
    assert(not CM.entities[entity], "Entity already exists")
    CM.entities[entity] = true

    entity:broadcastToComponents("onEntityAdded")
end


---@param entity Entity
function CM.removeEntity(entity)
    CM.entities[entity] = nil
    entity:broadcastToComponents("onEntityRemoved")
end


function CM.clear()
    for entity in pairs(CM.entities) do
        CM.removeEntity(entity)
    end
end


---@param funcname string
---@param ... any
function CM.broadcastToAllComponents(funcname, ...)
    for entity in pairs(CM.entities) do
        entity:broadcastToComponents(funcname, ...)
    end
end

return CM