local LayoutOptions    = require("lib.layout.layoutoptions")
local LayoutItem       = require("lib.layout.layoutitem")
local TextItem         = require("lib.layout.textitem")

local Button           = LayoutItem:new()

local DEFAULT_COLORS   = {
    normal = { 0.5, 0.5, 1 },
    hover = { 0.7, 0.7, 1 },
    active = { 0.9, 0.9, 1 },
    disabled = { 0.4, 0.4, 0.4 },
    textColor = { 0, 0, 0 },
}
DEFAULT_COLORS.__index = DEFAULT_COLORS

function Button:new(o)
    o = o or {}

    o.label = o.label or "Button"
    o.colors = o.colors or DEFAULT_COLORS
    setmetatable(o.colors, DEFAULT_COLORS)

    o.border = LayoutOptions.border({ 0, 0, 0 })

    o.children = {
        TextItem:new({
            content = o.label,
            font = o.font,
            color = o.colors.textColor
        })
    }

    o.padding = o.padding or LayoutOptions.padding(10)

    o = LayoutItem:new(o)
    setmetatable(o, self)
    self.__index = self

    -- Send state information here
    o.onClick = o.onClick or function() end
    o.state = o.state or "normal"

    return o
end

function Button:mousepressed(x, y, button, istouch, presses)
    if self.state == "disabled" then return false end
    if button == 1 and self.absRect:contains({ x, y }) then
        self.state = "active"
        return true
    end
    return false
end

function Button:mousereleased(x, y, button, istouch, presses)
    if self.state == "disabled" then return false end
    if self.state == "active" and self.absRect:contains({ x, y }) then
        self.onClick()
        self.state = "hover"
        return true
    end
    return false
end

function Button:mousemoved(x, y, dx, dy, istouch)
    if self.state == "disabled" then return false end
    if self.state == "normal" and self.absRect:contains({ x, y }) then
        self.state = "hover"
    elseif self.state ~= "normal" and not self.absRect:contains({ x, y }) then
        self.state = "normal"
    end
    return false
end

function Button:draw()
    love.graphics.push()
    love.graphics.translate(self.rect.x, self.rect.y)
    if self.state == "normal" then
        love.graphics.setColor(self.colors.normal)
    elseif self.state == "hover" then
        love.graphics.setColor(self.colors.hover)
    elseif self.state == "active" then
        love.graphics.setColor(self.colors.active)
    elseif self.state == "disabled" then
        love.graphics.setColor(self.colors.disabled)
    end

    love.graphics.rectangle("fill", 0, 0, self.rect.w, self.rect.h)

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
    for _, ch in ipairs(self.children) do
        ch:draw()
    end
    love.graphics.pop()
end

return Button
