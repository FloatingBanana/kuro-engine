local objectlayer = {}

function objectlayer:getObjectByName(name, unique)
    local objects = nil

    if not unique then objects = {} end

    for i, object in ipairs(self.objects) do
        if object.name == name then
            if unique then
                return object
            else
                objects[#objects+1] = object
            end
        end
    end

    return objects
end

function objectlayer:getObjectById(id)
    for i, object in ipairs(self.objects) do
        if object.id == id then
            return object
        end
    end
end

function objectlayer:getObjectByShape(shape, unique)
    local objects = nil

    if not unique then objects = {} end

    for i, object in ipairs(self.objects) do
        if object.shape == shape then
            if unique then
                return object
            else
                objects[#objects+1] = object
            end
        end
    end

    return objects
end

function objectlayer:getObjectsByProperty(property, value, unique)
    local objects = nil

    if not unique then objects = {} end

    for i, object in ipairs(self.objects) do
        if object.properties[property] == value then
            if unique then
                return object
            else
                objects[#objects+1] = object
            end
        end
    end

    return objects
end

function objectlayer:getObjectByProperties(properties, any, unique)
    local objects = nil

    if not unique then objects = {} end

    for i, object in ipairs(self.objects) do
        local add = true
        
        for key, val in pairs(properties) do
            if any then
                if object.properties[key] == val then
                    if unique then
                        return object
                    else
                        objects[#objects+1] = object
                        break
                    end
                end
            else
                if object.properties[key] ~= val then
                    add = false
                    break
                end
            end
        end

        if any and add then
            if unique then
                return object
            else
                objects[#objects+1] = object
            end
        end
    end

    return objects
end

function objectlayer:iterate()
    local size = #self.objects
    local i = 0

    return function()
        if i < size then
            i = i+1
            local obj = self.objects[i]

            if obj then
                return obj.name, obj
            end
        end
    end
end

function objectlayer:removeObject(obj)
    for i, object in ipairs(self.objects) do
        if obj == object then
            table.remove(self.objects, i)
            break
        end
    end
end

return objectlayer