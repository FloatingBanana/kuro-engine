local CM = {
    entities = {} ---@type table<Entity, boolean>
}

local waitingForRemove = {}

local function removeWaitingEntities()
    for entity in pairs(waitingForRemove) do
        waitingForRemove[entity] = nil
        CM.entities[entity] = nil
        entity:broadcastToComponents("onEntityRemoved", entity)
    end
end


---@param entity Entity
function CM.addEntity(entity)
    assert(not CM.entities[entity], "Entity already exists")
    CM.entities[entity] = true

    entity:broadcastToComponents("onEntityAdded", entity)
end


---@param entity Entity
function CM.removeEntity(entity)
    waitingForRemove[entity] = true
end


function CM.clear()
    for entity in pairs(CM.entities) do
        CM.removeEntity(entity)
    end
    removeWaitingEntities()
end


---@param funcname string
---@param ... any
function CM.broadcastToAllComponents(funcname, ...)
    for entity in pairs(CM.entities) do
        entity:broadcastToComponents(funcname, ...)
    end

    removeWaitingEntities()
end

return CM