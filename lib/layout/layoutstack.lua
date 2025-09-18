local LayoutStack = {}
function LayoutStack:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.items = {}

    return o
end

function LayoutStack:push(item)
    table.insert(self.items, item)
end

function LayoutStack:pop()
    assert(#self.items > 0, "Attempted to pop empty stack")
    table.remove(self.items, #self.items)
end

function LayoutStack:mousemoved(x, y, dx, dy, istouch)
    if #self.items == 0 then return false end
    self.items[#self.items]:mousemoved(x, y, dx, dy, istouch)
    return true
end

function LayoutStack:mousepressed(x, y, button, istouch, presses)
    if #self.items == 0 then return false end
    self.items[#self.items]:mousepressed(x, y, button, istouch, presses)
    return true
end

function LayoutStack:mousereleased(x, y, button, istouch, presses)
    if #self.items == 0 then return false end
    self.items[#self.items]:mousereleased(x, y, button, istouch, presses)
    return true
end

function LayoutStack:keypressed(key, scancode, isrepeat)
    if #self.items == 0 then return false end
    self.items[#self.items]:keypressed(key, scancode, isrepeat)
    return true
end

function LayoutStack:wheelmoved(dx, dy)
    if #self.items == 0 then return false end
    self.items[#self.items]:wheelmoved(dx, dy)
    return true
end

function LayoutStack:update(dt)
    if #self.items == 0 then return false end
    self.items[#self.items]:update(dt)
    return true
end

function LayoutStack:draw()
    for _, it in ipairs(self.items) do
        it:draw()
    end
    return false
end

return LayoutStack
