local Object = require "engine.3rdparty.classic.classic"

---@class Entity: Object
---
---@field public components table<string, Component>
---@field private _disabledComponents table<string, Component>
local Entity = Object:extend("Entity")

function Entity:new()
    self.components = {}
    self._disabledComponents = {}
end


---@param ... Component
---@return Entity
function Entity:attachComponents(...)
    for i=1, select("#", ...) do
        local comp = select(i, ...)

        assert(not self.components[comp.ClassName] and not self._disabledComponents[comp.ClassName], "Entity already has component "..comp.ClassName)
        self.components[comp.ClassName] = comp
        comp:onAttach(self)
    end

    return self
end


---@param compClassName string
---@return Entity
function Entity:detachComponent(compClassName)
    local comp = self.components[compClassName] or self._disabledComponents[compClassName]

    assert(comp, "Entity does not have component "..compClassName)
    comp:onDetach(self)

    self.components[compClassName] = nil
    self._disabledComponents[compClassName] = nil
    return self
end


function Entity:disableComponent(compClassName)
    local comp = self.components[compClassName]
    assert(comp, "Entity does not have component "..compClassName)

    self._disabledComponents[compClassName] = comp
    return self
end


function Entity:enableComponent(compClassName)
    local comp = self._disabledComponents[compClassName]
    assert(comp, "Entity does not have component "..compClassName)

    self.components[compClassName] = comp
    return self
end


---@param compClassName string
---@return Component?
function Entity:getComponent(compClassName)
    return self.components[compClassName]
end


---@param ... string
---@return boolean
function Entity:hasAllComponents(...)
    for i=1, select("#",...) do
        local compClassName = select(i,...)

        if not self:getComponent(compClassName) then
            return false
        end
    end

    return true
end


---@param funcname string
---@param ... any
function Entity:broadcastToComponents(funcname, ...)
    for _, comp in pairs(self.components) do
        if comp[funcname] then
            comp[funcname](comp, self, ...)
        end
    end
    return self
end


return Entity