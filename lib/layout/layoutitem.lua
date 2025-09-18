-- Layouting system heavily inspired by Clay
-- https://github.com/nicbarker/clay

local round = require("lib.round")
local LayoutOptions = require("lib.layout.layoutoptions")
local AABB = require("lib.aabb")

local defaultFont = love.graphics.newFont(12)

EPSILON = 0.000001
DEFAULT_SIZING = {
    width = { "fit", 0, nil },
    height = { "fit", 0, nil },
}

local function almostEqual(x, y)
    return math.abs(x - y) < EPSILON
end

local LayoutItem = {}

-- Constructs a new layout item.
function LayoutItem:new(o)
    o = o or {}
    if not o.children then o.children = {} end
    -- Filter out floating children
    o.floatingChildren = {}
    for i = #o.children, 1, -1 do
        local ch = o.children[i]
        if ch.floating then
            table.insert(o.floatingChildren, table.remove(o.children, i))
        end
    end

    table.sort(o.floatingChildren, function(a, b) return a.z < b.z end)

    -- Defer to default sizing
    o.sizing = o.sizing or DEFAULT_SIZING
    setmetatable(o.sizing, {
        __index = DEFAULT_SIZING,
    })

    -- Default settings that might be faster to type
    if o.sizing.width == "fit" then
        o.sizing.width = { "fit" }
    elseif o.sizing.width == "grow" then
        o.sizing.width = { "grow" }
    elseif type(o.sizing.width) == "number" then
        o.sizing.width = LayoutOptions.fixedSizing(o.sizing.width)
    end
    if o.sizing.height == "fit" then
        o.sizing.height = { "fit" }
    elseif o.sizing.height == "grow" then
        o.sizing.height = { "grow" }
    elseif type(o.sizing.height) == "number" then
        o.sizing.height = LayoutOptions.fixedSizing(o.sizing.height)
    end

    o.rect = o.rect or AABB:new(0, 0)
    o.minRect = o.minRect or AABB:new(0, 0)
    o.absRect = o.absRect or AABB:new(0, 0)
    o.direction = o.direction or "h"
    o.padding = o.padding or LayoutOptions.padding(0)
    o.childGap = o.childGap or 0
    o.alignment = o.alignment or { h = "begin", v = "begin" }
    o.alignment.h = o.alignment.h or "begin"
    o.alignment.v = o.alignment.v or "begin"
    o.drawer = o.drawer or function() end
    o.type = o.type or "generic"

    o.overflow = o.overflow or { h = "overflow", v = "overflow" }
    o.overflow.h = o.overflow.h or "overflow"
    o.overflow.v = o.overflow.v or "overflow"

    if o.overflow.h == "scroll" or o.overflow.v == "scroll" then
        assert(o.scrollState, "Must have scroll state")
    end

    o.scrollDistance = o.scrollDistance or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function LayoutItem:rebuildLayout()
    self:propagateIds()
    self:fitOnAxis(true)
    self:growShrinkOnAxis(true)
    self:fitOnAxis(false)
    self:growShrinkOnAxis(false)
    self:positionChildren(true)
    self:snapRects()
end

function LayoutItem:print(indent)
    local offset = ""
    if indent then
        for _ = 1, indent do
            offset = offset .. "    "
        end
    end
    print(string.format("%s%s", offset, tostring(self.rect)))
    for ch in self:allChildren() do
        ch:print(indent and indent + 1 or 1)
    end
end

-- Draw debug rectangles.
function LayoutItem:drawDebugRects()
    love.graphics.setFont(defaultFont)
    love.graphics.push()
    love.graphics.translate(self.rect.x, self.rect.y)
    love.graphics.setColor(1, 0, 1)
    love.graphics.rectangle("line", 0, 0, self.rect.w, self.rect.h)
    if (not self.children or #self.children == 0) and (not self.floatingChildren or #self.floatingChildren == 0) then
        love.graphics.print(tostring(self.rect), 0, 0)
    end
    for ch in self:allChildren() do
        ch:drawDebugRects()
    end
    love.graphics.pop()
end

-- Build this layout item's id map by recursively building the id maps of its
-- children.
function LayoutItem:propagateIds()
    self.idMap = {}
    if self.id then
        self.idMap[self.id] = self
    end

    for ch in self:allChildren() do
        ch:propagateIds()
        for k, v in pairs(ch.idMap) do
            assert(not self.idMap[k], string.format("Duplicate key %q", k))
            self.idMap[k] = v
        end
    end
end

-- Retrieves a layout item by it's ID.
function LayoutItem:getById(id)
    return self.idMap[id]
end

-- Size all container layout elements to fit their children on a particular
-- axis.
function LayoutItem:fitOnAxis(horizontal)
    local mode = horizontal and self.sizing.width or self.sizing.height
    -- If this object has 'fit' or 'grow' sizing, then the width of this container
    -- is determined by the width of all its children.
    if mode[1] == "fit" or mode[1] == "grow" then
        local childSize, minChildSize = 0, 0
        if (self.direction == "h") == horizontal then
            -- When sizing along the main axis, the size of the children is the
            -- sum of all the child sizes, plus all the gaps between each child
            childSize = (#self.children - 1) * self.childGap
            for _, ch in ipairs(self.children) do
                ch:fitOnAxis(horizontal)
                childSize = childSize + (horizontal and ch.rect.w or ch.rect.h)
                minChildSize = minChildSize + (horizontal and ch.minRect.w or ch.minRect.h)
            end
        else
            -- When sizing along the cross axis, the size of the children is the
            -- size of the largest child.
            for _, ch in ipairs(self.children) do
                ch:fitOnAxis(horizontal)
                childSize = math.max(childSize,
                    horizontal and ch.rect.w or ch.rect.h)
                minChildSize = math.max(minChildSize,
                    horizontal and ch.minRect.w or ch.minRect.h)
            end
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
    elseif mode[1] == "percent" then
        -- If this object has 'percent' sizing, then its size is determined by the size of its parent.
        for _, ch in ipairs(self.children) do
            ch:fitOnAxis(horizontal)
        end
        if horizontal then
            self.rect.w = 0
        else
            self.rect.h = 0
        end
    end

    -- Floating children are separate from the document flow, so size each of them
    -- separately.
    for _, ch in ipairs(self.floatingChildren) do
        ch:fitOnAxis(horizontal)
    end
end

-- Find all layout items with growable sizing and grow them to fill
-- available space.
function LayoutItem:growShrinkOnAxis(horizontal)
    if horizontal then
        self.childWidth = 0
    else
        self.childHeight = 0
    end

    for _, ch in ipairs(self.floatingChildren) do
        local mode = horizontal and ch.sizing.width or ch.sizing.height
        if mode[1] == "percent" then
            if horizontal then
                ch.rect.w = self.rect.w * (mode[2] or 0)
            else
                ch.rect.h = self.rect.h * (mode[2] or 0)
            end
        end
        ch:growShrinkOnAxis(horizontal)
    end

    if #self.children == 0 then return end

    -- Expand percentage containers to fill space
    for _, ch in ipairs(self.children) do
        local mode = horizontal and ch.sizing.width or ch.sizing.height
        if mode[1] == "percent" then
            if horizontal then
                local contentSize = self.rect.w
                    - self.padding.left - self.padding.right
                    - self.childGap * (#self.children - 1)
                ch.rect.w = contentSize * (mode[2] or 0)
            else
                local contentSize = self.rect.h
                    - self.padding.top - self.padding.bottom
                    - self.childGap * (#self.children - 1)
                ch.rect.h = contentSize * (mode[2] or 0)
            end
        end
    end

    -- If scaling along cross axis, just fill/shrink to content size
    if horizontal == (self.direction == "v") then
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
                local mode = horizontal and ch.sizing.width or ch.sizing.height
                local remainingSize = horizontal and contentSize - ch.rect.w or contentSize - ch.rect.h
                if mode[1] == "grow" and remainingSize > EPSILON then
                    if horizontal then
                        ch.rect.w = math.min(contentSize, ch.sizing.width[3] and ch.sizing.width[3] or 1e38)
                    else
                        ch.rect.h = math.min(contentSize, mode[3] and mode[3] or 1e38)
                    end
                end
                if mode[1] ~= "percent" then
                    if horizontal then
                        ch.rect.w = math.min(ch.rect.w, contentSize)
                        ch.rect.w = math.max(ch.rect.w, ch.minRect.w)
                        self.childWidth = math.max(self.childWidth, ch.rect.w)
                    else
                        ch.rect.h = math.min(ch.rect.h, contentSize)
                        ch.rect.h = math.max(ch.rect.h, ch.minRect.h)
                        self.childHeight = math.max(self.childHeight, ch.rect.h)
                    end
                end
            elseif ch.type == "text" then
                if horizontal then
                    ch.rect.w = math.min(contentSize, ch.rect.w)
                end
            end
        end
    else
        -- Otherwise, if scaling along main axis, then there are three cases:
        -- - If there are no growable elements or if there's no space remaining, we're done.
        -- - If there is excess space, repeatedly grow the smallest growable element(s) until they can't grow any further.
        -- - If there isn't enough space, repeatedly shrink the largest shrinkable element(s) until they can't shrink any further.
        local remainingSize
        if horizontal then
            remainingSize = self.rect.w
            local childSize = 0
            for _, ch in ipairs(self.children) do
                childSize = childSize + ch.rect.w
            end
            remainingSize = remainingSize
                - childSize
                - (#self.children - 1) * self.childGap
                - self.padding.left - self.padding.right
        else
            remainingSize = self.rect.h
            local childSize = 0
            for _, ch in ipairs(self.children) do
                childSize = childSize + ch.rect.h
            end
            remainingSize = remainingSize
                - childSize
                - (#self.children - 1) * self.childGap
                - self.padding.top - self.padding.bottom
        end

        if remainingSize > EPSILON then
            local growableChildren = {}
            for _, ch in ipairs(self.children) do
                local mode = horizontal and ch.sizing.width or ch.sizing.height
                local childSize = horizontal and ch.rect.w or ch.rect.h
                if mode[1] == "grow" and (not mode[3] or almostEqual(mode[3], childSize)) then
                    table.insert(growableChildren, ch)
                end
            end

            while remainingSize > EPSILON and #growableChildren > 0 do
                -- Find smallest and second-smallest growable elements, and grow
                -- all smallest elements to be the same size as the second
                -- smallest elements if possible.
                local smallest, secondSmallest = 1e38, 1e38
                local sizeToAdd = remainingSize
                for _, ch in ipairs(growableChildren) do
                    local childSize = horizontal and ch.rect.w or ch.rect.h
                    if childSize < smallest then
                        secondSmallest = smallest
                        smallest = childSize
                    end
                    if childSize > smallest then
                        secondSmallest = math.min(secondSmallest, childSize)
                        sizeToAdd = secondSmallest - smallest
                    end
                end
                sizeToAdd = math.min(sizeToAdd, remainingSize / #growableChildren)
                for i = #growableChildren, 1, -1 do
                    local ch = growableChildren[i]
                    local childSize = horizontal and ch.rect.w or ch.rect.h
                    if almostEqual(childSize, smallest) then
                        local mode = horizontal and ch.sizing.width or ch.sizing.height
                        if not mode[3] then
                            if horizontal then
                                ch.rect.w = ch.rect.w + sizeToAdd
                            else
                                ch.rect.h = ch.rect.h + sizeToAdd
                            end
                            remainingSize = remainingSize - sizeToAdd
                        else
                            local amount = math.min(sizeToAdd, ch.sizing.width[3] - ch.rect.w)
                            if horizontal then
                                ch.rect.w = ch.rect.w + amount
                                remainingSize = remainingSize - amount
                                if almostEqual(mode[3], ch.rect.w) then
                                    table.remove(growableChildren, i)
                                end
                            else
                                ch.rect.h = ch.rect.h + amount
                                remainingSize = remainingSize - amount
                                if almostEqual(mode[3], ch.rect.h) then
                                    table.remove(growableChildren, i)
                                end
                            end
                        end
                    end
                end
            end
        elseif remainingSize < -EPSILON then
            -- shrink elements
            local shrinkableChildren = {}
            for _, ch in ipairs(self.children) do
                local childSize = horizontal and ch.rect.w or ch.rect.h
                local minSize = horizontal and ch.minRect.w or ch.minRect.h
                if childSize > minSize then
                    table.insert(shrinkableChildren, ch)
                end
            end

            local loops = 0
            while remainingSize < -EPSILON and #shrinkableChildren > 0 do
                -- Find largest and second-largest shrinkable elements, and shrink
                -- all largest elements to be the same size as the second
                -- largest elements if possible.
                local largest, secondLargest = 0, 0
                local sizeToRemove = -remainingSize
                for _, ch in ipairs(shrinkableChildren) do
                    local childSize = horizontal and ch.rect.w or ch.rect.h
                    if childSize > largest then
                        secondLargest = largest
                        largest = childSize
                    end
                    if childSize < largest then
                        secondLargest = math.max(secondLargest, childSize)
                        sizeToRemove = largest - secondLargest
                    end
                end
                sizeToRemove = math.min(sizeToRemove, -remainingSize / #shrinkableChildren)
                for i = #shrinkableChildren, 1, -1 do
                    local ch = shrinkableChildren[i]
                    local childSize = horizontal and ch.rect.w or ch.rect.h
                    if almostEqual(childSize, largest) then
                        if horizontal then
                            local amount = math.min(sizeToRemove, ch.rect.w - ch.minRect.w)
                            ch.rect.w = ch.rect.w - amount
                            remainingSize = remainingSize + amount
                            if almostEqual(ch.minRect.w, ch.rect.w) then
                                table.remove(shrinkableChildren, i)
                            end
                        else
                            local amount = math.min(sizeToRemove, ch.rect.h - ch.minRect.h)
                            ch.rect.h = ch.rect.h - amount
                            remainingSize = remainingSize + amount
                            if almostEqual(ch.minRect.h, ch.rect.h) then
                                table.remove(shrinkableChildren, i)
                            end
                        end
                    end
                end
                loops = loops + 1
            end
        end
    end

    -- After sizing all elements, recursively do the grow-shrink steps
    -- to each child, and recompute the total width of the children.
    if horizontal then
        self.childWidth = 0
        for _, ch in ipairs(self.children) do
            self.childWidth = self.childWidth + ch.rect.w
            -- If any child is a text object, then wrap the text
            if ch.type == "generic" then
                ch:growShrinkOnAxis(horizontal)
            elseif ch.type == "text" then
                ch:wrapText()
            end
        end
        self.childWidth = self.childWidth + (#self.children - 1) * self.childGap
    else
        self.childHeight = 0
        for _, ch in ipairs(self.children) do
            self.childHeight = self.childHeight + ch.rect.h
            -- If any child is a text object, then wrap the text
            if ch.type == "generic" then
                ch:growShrinkOnAxis(horizontal)
            elseif ch.type == "text" then
                ch:wrapText()
            end
        end
        self.childHeight = self.childHeight + (#self.children - 1) * self.childGap
    end
end

-- Compute thhe positions of each child of the given element.
function LayoutItem:positionChildren(root)
    if root then
        self.absRect = AABB:new(0, 0, self.rect.w, self.rect.h)
    end

    if self.direction == "h" then
        local xx = self.padding.left

        if self.alignment.h == "center" then
            xx = (self.rect.w - self.childWidth) / 2
        elseif self.alignment.h == "end" then
            xx = self.rect.w - self.childWidth - self.padding.right
        end

        for _, ch in ipairs(self.children) do
            ch.rect.x, ch.rect.y = xx, self.padding.top
            if self.alignment.h == "center" then
                ch.rect.y = (self.rect.h - ch.rect.h) / 2
            elseif self.alignment.h == "end" then
                ch.rect.y = self.rect.h - ch.rect.h - self.padding.bottom
            end

            ch.absRect = AABB:new(
                ch.rect.x + self.absRect.x, ch.rect.y + self.absRect.y,
                ch.rect.w, ch.rect.h)

            xx = xx + ch.rect.w + self.childGap
            ch:positionChildren()
        end
    else
        local yy = self.padding.top
        if self.alignment.v == "center" then
            yy = (self.rect.h - self.childHeight) / 2
        elseif self.alignment.v == "end" then
            yy = self.rect.h - self.childHeight - self.padding.bottom
        end

        for _, ch in ipairs(self.children) do
            ch.rect.x, ch.rect.y = self.padding.left, yy
            if self.alignment.h == "center" then
                ch.rect.x = (self.rect.w - ch.rect.w) / 2
            elseif self.alignment.h == "end" then
                ch.rect.x = self.rect.w - ch.rect.w - self.padding.right
            end

            ch.absRect = AABB:new(
                ch.rect.x + self.absRect.x, ch.rect.y + self.absRect.y,
                ch.rect.w, ch.rect.h)

            yy = yy + ch.rect.h + self.childGap
            ch:positionChildren()
        end
    end

    for _, ch in ipairs(self.floatingChildren) do
        local f = ch.floating
        ch.rect.x, ch.rect.y = 0, 0
        if f.anchor.h == "center" then
            ch.rect.x = (self.rect.w - ch.rect.w) / 2
        elseif f.anchor.h == "end" then
            ch.rect.x = self.rect.w - ch.rect.w
        end
        if f.anchor.v == "center" then
            ch.rect.y = (self.rect.h - ch.rect.h) / 2
        elseif f.anchor.v == "end" then
            ch.rect.y = self.rect.h - ch.rect.h
        end
        ch.rect.x, ch.rect.y = ch.rect.x + f.x, ch.rect.y + f.y
        ch.absRect = AABB:new(
            ch.rect.x + self.absRect.x, ch.rect.y + self.absRect.y,
            ch.rect.w, ch.rect.h)
        ch:positionChildren()
    end
end

-- Snap all rects to integer coordinates
function LayoutItem:snapRects()
    self.rect.x = round(self.rect.x)
    self.rect.y = round(self.rect.y)
    self.rect.w = round(self.rect.w)
    self.rect.h = round(self.rect.h)
    for ch in self:allChildren() do
        ch:snapRects()
    end
end

-- These input callbacks will propagate all input events throughout the
-- layout tree.
-- FIXME: Maybe generalize this a bit to have a generic event handler function
-- just so you won't have to define all these repetitive, similar functions.

function LayoutItem:mousepressed(x, y, button, istouch, presses)
    for ch in self:allChildren() do
        local handled = ch:mousepressed(x, y, button, istouch, presses)
        if handled then return handled end
    end
    return false
end

function LayoutItem:mousereleased(x, y, button, istouch, presses)
    for ch in self:allChildren() do
        local handled = ch:mousereleased(x, y, button, istouch, presses)
        if handled then return handled end
    end
    return false
end

function LayoutItem:mousemoved(x, y, dx, dy, istouch)
    for ch in self:allChildren() do
        local handled = ch:mousemoved(x, y, dx, dy, istouch)
        if handled then return handled end
    end
    return false
end

function LayoutItem:keypressed(key, scancode, isrepeat)
    for ch in self:allChildren() do
        local handled = ch:keypressed(key, scancode, isrepeat)
        if handled then return handled end
    end
    return false
end

function LayoutItem:wheelmoved(dx, dy)
    for ch in self:allChildren() do
        local handled = ch:wheelmoved(dx, dy)
        if handled then return handled end
    end
    if self.scrollDistance.h and dx ~= 0 then
        local extraSpace = (self.childWidth + self.padding.left + self.padding.right - self.rect.w)
        if extraSpace > 0 then
            self.scrollState.x = self.scrollState.x - dx * (self.scrollDistance.h / extraSpace)
            self.scrollState.x = math.max(0, math.min(1, self.scrollState.x))
        end
    end
    if self.scrollDistance.v and dy ~= 0 then
        local extraSpace = (self.childHeight + self.padding.top + self.padding.bottom - self.rect.h)
        if extraSpace > 0 then
            self.scrollState.y = self.scrollState.y - dy * (self.scrollDistance.v / extraSpace)
            self.scrollState.y = math.max(0, math.min(1, self.scrollState.y))
        end
    end
    return false
end

function LayoutItem:update(dt)
    for ch in self:allChildren() do
        local handled = ch:update(dt)
        if handled then return handled end
    end
    return false
end

-- Draw the layout tree.
function LayoutItem:draw()
    love.graphics.push("all")
    love.graphics.translate(self.rect.x, self.rect.y)
    local ww, wh = love.graphics.getDimensions()
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


    do
        love.graphics.push("all")

        if self.overflow.h ~= "overflow" and self.overflow.v ~= "overflow" then
            love.graphics.intersectScissor(self.absRect.x, self.absRect.y, self.absRect.w, self.absRect.h)
        elseif self.overflow.h ~= "overflow" then
            love.graphics.intersectScissor(self.absRect.x, self.absRect.y, self.absRect.w, self.absRect.h)
        elseif self.overflow.v ~= "overflow" then
            love.graphics.intersectScissor(self.absRect.x, self.absRect.y, self.absRect.w, self.absRect.h)
        end

        self.drawer(self)
        if
            self.overflow.h == "scroll" and
            self.childWidth + self.padding.left + self.padding.right >= self.absRect.w
        then
            local offset = 0
            -- get everything relative to top
            if self.alignment.h == "center" then
                offset = (-self.childWidth + self.rect.w) / 2
            elseif self.alignment.h == "end" then
                offset = (-self.childWidth + self.rect.w)
            end
            offset = offset + self.scrollState.x * (-self.childWidth + self.rect.w)
            love.graphics.translate(offset, 0)
        end
        if
            self.overflow.v == "scroll" and
            self.childHeight + self.padding.top + self.padding.bottom >= self.absRect.h
        then
            local offset = 0
            -- get everything relative to top
            if self.alignment.v == "center" then
                offset = (self.childHeight - self.rect.h) / 2
            elseif self.alignment.v == "end" then
                offset = (self.childHeight - self.rect.h)
            end
            offset = offset + self.scrollState.y * (-self.childHeight + self.rect.h)
            love.graphics.translate(0, offset)
        end

        -- TODO: Implement pruning out invisible objects when scrolling.
        for _, ch in ipairs(self.children) do
            ch:draw()
        end
        love.graphics.pop()
    end

    -- Draw floating children first
    for _, ch in ipairs(self.floatingChildren) do
        ch:draw()
    end

    love.graphics.pop()
end

function LayoutItem:allChildren()
    local co = coroutine.create(function()
        for _, ch in ipairs(self.children) do
            coroutine.yield(ch)
        end
        for _, ch in ipairs(self.floatingChildren) do
            coroutine.yield(ch)
        end
    end)

    return function()
        local _, ch = coroutine.resume(co)
        return ch
    end
end

function LayoutItem:sortChildren()
    self.floatingChildren = self.floatingChildren or {}
    for i = #self.children, 1, -1 do
        local ch = self.children[i]
        if ch.floating then
            table.insert(self.floatingChildren, table.remove(self.children, i))
        end
    end
    table.sort(self.floatingChildren, function(a, b) return a.z < b.z end)
end

return LayoutItem
