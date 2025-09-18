local LayoutBuilder = {}

function LayoutBuilder:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.itemStack = {}
    return o
end

function LayoutBuilder:push(item)
    table.insert(self.itemStack, item)
end

function LayoutBuilder:pop()
    if #self.itemStack == 0 then
        error("Attempted pop with empty stack")
    end

    local top = table.remove(self.itemStack, #self.itemStack)
    top:sortChildren()

    if #self.itemStack == 0 then
        return top
    end

    table.insert(self.itemStack[#self.itemStack].children, top)
    return top
end

function LayoutBuilder:with(item, body)
    body = body or function() end
    self:push(item)
    body()
    return self:pop()
end

return LayoutBuilder
