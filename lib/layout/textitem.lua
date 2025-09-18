local LayoutItem = require("lib.layout.layoutitem")
local LayoutOptions = require("lib.layout.layoutoptions")
local AABB = require("lib.aabb")

local TextItem = LayoutItem:new()

local defaultFont = love.graphics.newFont(12)

function TextItem:new(o)
    o = o or {}

    o.rect = o.rect or AABB:new(0, 0)
    o.minRect = o.minRect or AABB:new(0, 0)
    o.absRect = o.absRect or AABB:new(0, 0)
    o.type = "text"
    o.font = o.font or defaultFont
    o.content = o.content or ""
    o.minLength = o.minLength or o.font:getWidth("M")
    o.color = o.color or { 0, 0, 0 }
    o.children = {}

    o = LayoutItem:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function TextItem:fitOnAxis(horizontal)
    if horizontal then
        self.rect.w = self.font:getWidth(self.content)
        self.minRect.w = self.minLength
    else
        if self.wrap then
            self.rect.h = self.font:getHeight() * self.font:getLineHeight() * #self.wrappedContent
            self.minRect.h = self.rect.h
        else
            self.rect.h = self.font:getHeight()
            self.minRect.h = self.rect.h
        end
    end
end

function TextItem:wrapText()
    if self.wrap then
        local _, wrappedContent = self.font:getWrap(self.content, self.rect.w)
        self.wrappedContent = wrappedContent
    end
end

function TextItem:draw()
    love.graphics.push()
    love.graphics.translate(self.rect.x, self.rect.y)
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color)
    if self.wrap then
        local lh = self.font:getLineHeight() * self.font:getHeight()
        for i, ln in ipairs(self.wrappedContent) do
            love.graphics.print(ln, self.font, 0, (i - 1) * lh)
        end
    else
        love.graphics.print(self.content, self.font)
    end
    love.graphics.pop()
end

return TextItem
