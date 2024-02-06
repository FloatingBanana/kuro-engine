local Object = require "engine.3rdparty.classic.classic"

---@class Entity: Object
---
---@field public components table<string, Component>
local Entity = Object:extend("Entity")

function Entity:new()
    self.components = {}
end


---@param ... Component
---@return Entity
function Entity:attachComponents(...)
    for i=1, select("#", ...) do
        local comp = select(i, ...)

        assert(not self.components[comp.ClassName], "Entity already has component "..comp.ClassName)
        self.components[comp.ClassName] = comp
        comp:onAttach(self)
    end

    return self
end


---@param compClassName string
---@return Entity
function Entity:detachComponent(compClassName)
    self.components[compClassName]:onDetach(self)
    self.components[compClassName] = nil
    return self
end


---@param compClassName string
---@return boolean
function Entity:hasComponent(compClassName)
    comp = self.components[compClassName]
    return comp ~= nil and comp.enabled
end


---@param ... string
---@return boolean
function Entity:hasAllComponents(...)
    for i=1, select("#",...) do
        local compClassNames = select(i,...)

        if not self:hasComponent(compClassNames) then
            return false
        end
    end

    return true
end


---@param funcname string
---@param ... any
function Entity:broadcastToComponents(funcname, ...)
    for _, comp in pairs(self.components) do
        if comp.enabled and comp[funcname] then
            comp[funcname](comp, self, ...)
        end
    end
end


return Entity