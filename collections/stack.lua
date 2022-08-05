local Stack = Object:extend()

function Stack:new(...)
    for i=1, select("#", ...)do
        self:push(select(i, ...))
    end
end

function Stack:push(item)
    table.insert(self, item)
end

function Stack:pop()
    return table.remove(self)
end

function Stack:peek()
    return self[#self]
end

return Stack