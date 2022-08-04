local Deque = Object:extend()

function Deque:new(...)
    self.first = 0
    self.last = -1

    for i=1, select("#", ...)do
        self:pushRight(select(i, ...))
    end
end

function Deque:pushLeft(item)
    self.first = self.first - 1
    self[self.first] = item
end

function Deque:pushRight(item)
    self.last = self.last + 1
    self[self.last] = item
end

function Deque:popLeft()
    assert(self:getLenght() > 0, "Deque is empty")

    local item = self:peekLeft()
    self[self.first] = nil
    self.first = self.first + 1

    return item
end

function Deque:popRight()
    assert(self:getLenght() > 0, "Deque is empty")

    local item = self:peekRight()
    self[self.last] = nil
    self.last = self.last - 1

    return item
end

function Deque:peekLeft()
    return self[self.last]
end

function Deque:peekRight()
    return self[self.first]
end

function Deque:getLenght()
    return math.abs(self.first - self.last + 1)
end

function Deque:getItem(index)
    return self[self.first + (index - 1)]
end


local function iter(this, i)
    i = i+1
    local item = this:getItem(i)

    if item then
        return item, i
    end
end

function Deque:iterate()
    return iter, self, 0
end

return Deque