local LayoutItem = require("lib.layout.layoutitem")
local AABB = require("lib.aabb")

local TabContainer = LayoutItem:new({
    tab = 1
})

function TabContainer:fitOnAxis(horizontal)
    local s = self:getSizing()
    local mode = horizontal and s.width or s.height
    if mode[1] == "fit" or mode[1] == "grow" then
        local childSize, minChildSize = 0, 0
        -- Get the size of the largest child along this axis
        for _, ch in ipairs(self.children) do
            ch:fitOnAxis(horizontal)
            childSize = math.max(childSize,
                horizontal and ch.rect.w or ch.rect.h)
            minChildSize = math.max(minChildSize,
                horizontal and ch.minRect.w or ch.minRect.h)
        end
        local rawSize, rawMinSize = childSize, minChildSize
        if horizontal then
            rawSize = rawSize + self.padding.left + self.padding.right
            rawMinSize = rawMinSize + self.padding.left + self.padding.right
            self.rect.w = math.max(mode[2] or 0, rawSize)
            self.minRect.w = math.max(mode[2] or 0, rawMinSize)
            if mode[3] then
                self.rect.w = math.min(mode[3], self.rect.w)
                self.minRect.w = math.min(mode[3], self.minRect.w)
            end
        else
            rawSize = rawSize + self.padding.top + self.padding.bottom
            rawMinSize = rawMinSize + self.padding.top + self.padding.bottom
            self.rect.h = math.max(mode[2] or 0, rawSize)
            self.minRect.h = math.max(mode[2] or 0, rawMinSize)
            if mode[3] then
                self.rect.h = math.min(mode[3], self.rect.h)
                self.minRect.h = math.min(mode[3], self.minRect.w)
            end
        end
    end

    for _, ch in ipairs(self.floatingChildren) do
        ch:fitOnAxis(horizontal)
    end
end

function TabContainer:growShrinkOnAxis(horizontal)
    -- Special cases
    if #self.children == 0 then return end
    -- Use cross-axis scaling for all tab container elements
    local contentSize
    if horizontal then
        contentSize = self.rect.w - self.padding.left - self.padding.right
        self.childWidth = 0
    else
        contentSize = self.rect.h - self.padding.top - self.padding.bottom
        self.childHeight = 0
    end
    for _, ch in ipairs(self.children) do
        if ch.type == "generic" then
            local s = ch:getSizing()
            local mode = horizontal and s.width or s.height
            local remainingSize = horizontal and contentSize - ch.rect.w or contentSize - ch.rect.h
            if mode[1] == "grow" and remainingSize > EPSILON then
                if horizontal then
                    ch.rect.w = math.min(contentSize, s.width[3] and s.width[3] or 1e38)
                else
                    ch.rect.h = math.min(contentSize, mode[3] and mode[3] or 1e38)
                end
            end
            if horizontal then
                ch.rect.w = math.min(ch.rect.w, contentSize)
                ch.rect.w = math.max(ch.rect.w, ch.minRect.w)
                self.childWidth = math.max(self.childWidth, ch.rect.w)
            else
                ch.rect.h = math.min(ch.rect.h, contentSize)
                ch.rect.h = math.max(ch.rect.h, ch.minRect.h)
                self.childHeight = math.max(self.childHeight, ch.rect.h)
            end
            ch:growShrinkOnAxis(horizontal)
        elseif ch.type == "text" then
            if horizontal then
                ch.rect.w = math.min(contentSize, ch.rect.w)
            end
        end
    end
end

function TabContainer:positionChildren(root)
    if root then
        self.absRect = AABB:new(0, 0, self.rect.w, self.rect.h)
    end

    for _, ch in ipairs(self.children) do
        ch.rect.x, ch.rect.y = self.padding.left, self.padding.top
        if self.alignment.h == "center" then
            ch.rect.x = (self.rect.w - ch.rect.w) / 2
        elseif self.alignment.h == "end" then
            ch.rect.x = self.rect.w - ch.rect.w - self.padding.right
        end

        if self.alignment.v == "center" then
            ch.rect.y = (self.rect.h - ch.rect.h) / 2
        elseif self.alignment.v == "end" then
            ch.rect.y = self.rect.h - ch.rect.h - self.padding.bottom
        end
        ch.absRect = AABB:new(
            ch.rect.x + self.absRect.x, ch.rect.y + self.absRect.y,
            ch.rect.w, ch.rect.h)

        ch:positionChildren()
    end
end

function TabContainer:mousepressed(x, y, button, istouch, presses)
    return self.children[self.tab]:mousepressed(x, y, button, istouch, presses)
end

function TabContainer:mousereleased(x, y, button, istouch, presses)
    return self.children[self.tab]:mousereleased(x, y, button, istouch, presses)
end

function TabContainer:mousemoved(x, y, dx, dy, istouch)
    return self.children[self.tab]:mousemoved(x, y, dx, dy, istouch)
end

function TabContainer:keypressed(key, scancode, isrepeat)
    return self.children[self.tab]:keypressed(key, scancode, isrepeat)
end

function TabContainer:draw()
    love.graphics.push()
    love.graphics.translate(self.rect.x, self.rect.y)
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", 0, 0, self.rect.w, self.rect.h)
    end

    if self.border then
        love.graphics.setColor(self.border.top)
        love.graphics.line(0, 0, self.rect.w, 0)
        love.graphics.setColor(self.border.bottom)
        love.graphics.line(0, self.rect.h, self.rect.w, self.rect.h)
        love.graphics.setColor(self.border.left)
        love.graphics.line(0, 0, 0, self.rect.h)
        love.graphics.setColor(self.border.right)
        love.graphics.line(self.rect.w, 0, self.rect.w, self.rect.h)
    end

    self.drawer(self)
    self.children[self.tab]:draw()
    love.graphics.pop()
end

return TabContainer
