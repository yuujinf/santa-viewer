local Layout = require("lib.layout")
local colorFromHex = require("lib.colorFromHex")

local Presentation = require("presentation")
local ImageViewer = require("imageviewer")
local Theme = require("theme")
local WB = require("wrappingbackground")

local Presenter = {}

local presenterFont = love.graphics.newFont(24)

local senderFontA = love.graphics.newFont(24)
local senderFontB = love.graphics.newFont(48)

local sentColor = colorFromHex("648fff")
local recvColor = colorFromHex("dc267f")

function Presenter:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function Presenter:initialize()
    self.imageViewer = ImageViewer:new()
    self.presentation = self.presentation or (self.projectName and Presentation.load(self.projectName))
    self.theme = self.theme or (self.themeName and Theme.load(self.themeName)) or Theme.nullTheme

    if self.theme.bg then
        self.bg = WB:new({
            image = self.theme.bg,
            mode = self.theme.spec.bgMode,
        })
    else
        self.bg = WB:new({
            filename = "assets/testBg.png",
            mode = self.theme.spec.bgMode,
        })
    end

    self.currentSub = 1
    self.currentItem = 1

    self.scroll = 0
    self.leftPanelVisible = true

    self.presentedState = {}

    self:updateImageViewer()

    self:rebuildLayout()
end

function Presenter:rebuildLayout()
    self.screenW, self.screenH = love.graphics.getDimensions()
    local b = Layout.newBuilder()
    self.layout = b:with(Layout.newItem {
            sizing = Layout.rectSizing(self.screenW, self.screenH),
            padding = Layout.padding(10),
            childGap = 10,
        },
        function()
            b:with(Layout.newItem {
                id = "leftPanel",
                sizing = {
                    width = Layout.percentSizing(0.2),
                    height = "grow",
                },
                drawer = function(l)
                    if self.leftPanelVisible then
                        self:drawLeftPanel(l.rect)
                    end
                end
            })
        end)

    self.layout:rebuildLayout()
    self.leftPanelRect = self.layout:getById("leftPanel").absRect
end

function Presenter:updateImageViewer()
    -- FIXME: This is a blocking operation, and is slow on large images. Fix it in the future to use
    -- threads to do the file load asynchronously
    local mediaFilename = self.presentation.submissions[self.currentSub].items[self.currentItem].path
    self.imageViewer:setImage(mediaFilename)
    self.imageViewer:zoomToFit()
    if not self.presentedState[self.presentation.submissions[self.currentSub].recipient] then
        self.imageViewer.hide = true
    else
        self.imageViewer.hide = false
    end
end

function Presenter:next()
    self.currentItem = self.currentItem + 1
    if self.currentItem <= self.presentation:numberOfItems(self.currentSub) then return end

    self.currentItem = 1
    local s = self.currentSub + 1
    if s >= self.presentation:numberOfSubmissions() then s = 1 end
    self:setSubmission(s)
end

function Presenter:prev()
    self.currentItem = self.currentItem - 1
    if self.currentItem >= 1 then return end

    local s = self.currentSub - 1
    if s <= 1 then s = self.presentation:numberOfSubmissions() end
    self:setSubmission(s)
    self.currentItem = self.presentation:numberOfItems(self.currentSub)
end

function Presenter:setSubmission(i)
    self.currentSub = i
    local newScroll = (self.leftPanelRect.h - presenterFont:getHeight()) / 2
        - presenterFont:getHeight() * (self.currentSub - 1)

    self.scroll = newScroll / (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight())
    self.scroll = math.max(0, math.min(1, self.scroll))
end

function Presenter:mousemoved(x, y, dx, dy, istouch)
    self.imageViewer:mousemoved(x, y, dx, dy, istouch)

    if self.leftPanelVisible then
        local rx, ry = x - (self.leftPanelRect.x + 5),
            y - (self.leftPanelRect.y + 5) -
            (self.scroll * (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight()))

        if rx >= 0 and rx <= self.leftPanelRect.w then
            self.hover = math.floor(ry / presenterFont:getHeight()) + 1
        else
            self.hover = nil
        end
    end
end

function Presenter:mousepressed(x, y, button, istouch, presses)
    if self.hover and self.leftPanelVisible then
        self:setSubmission(self.hover)
        self.currentItem = 1

        self:updateImageViewer()
    end
    self.imageViewer:mousepressed(x, y, button, istouch, presses)
end

function Presenter:mousereleased(x, y, button, istouch, presses)
    self.imageViewer:mousereleased(x, y, button, istouch, presses)
end

function Presenter:wheelmoved(dx, dy)
    if not self.leftPanelRect:contains({ love.mouse.getPosition() }) or dy == 0 then
        self.imageViewer:wheelmoved(dx, dy)
        return
    end

    self.scroll = math.max(0, math.min(1, self.scroll + -0.05 * dy))
end

function Presenter:scrollItemPosition(i)
    local y = self.scroll * (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight())
    y = y + (i - 1) * presenterFont:getHeight()
    return y
end

function Presenter:keypressed(key, scancode, isrepeat)
    local rc = self.presentation.submissions[self.currentSub].recipient
    if key == "right" then
        if not self.presentedState[rc] then
            self.imageViewer.hide = false
            self.presentedState[rc] = {
                image = true,
            }
        elseif
            self.currentItem == self.presentation:numberOfItems(self.currentSub) and
            not self.presentedState[rc].recipient
        then
            self.presentedState[rc].recipient = true
        elseif
            self.currentItem == self.presentation:numberOfItems(self.currentSub) and
            not self.presentedState[rc].sender
        then
            self.presentedState[rc].sender = true
        else
            self:next()
            self:updateImageViewer()
        end
    elseif key == "space" then
        self.imageViewer.hide = false
        if not self.presentedState[rc] then
            self.presentedState[rc] = {
                image = true,
            }
        elseif not self.presentedState[rc].recipient then
            self.presentedState[rc].recipient = true
        elseif not self.presentedState[rc].sender then
            self.presentedState[rc].sender = true
        end
    elseif scancode == "1" and self.presentedState[rc] then
        self.presentedState[rc].recipient = true
    elseif scancode == "2" and self.presentedState[rc] then
        self.presentedState[rc].sender = true
    elseif scancode == "3" and self.presentedState[rc] then
        self.presentedState[rc].sender = true
        self.presentedState[rc].recipient = true
    elseif key == "left" then
        self:prev()
        self:updateImageViewer()
    elseif scancode == "0" then
        self.imageViewer:zoomToFit()
    elseif key == "tab" then
        self.leftPanelVisible = not self.leftPanelVisible
    elseif scancode == "a" and self.presentedState[rc] and self.presentedState[rc].recipient then
        -- Jump to the recipient's gift
        local sub = self.presentation.submissions[self.currentSub]
        self:setSubmission(self.presentation:findSubIndexBySender(sub.recipient))
        self.currentItem = 1
        self:updateImageViewer()
    elseif scancode == "d" and self.presentedState[rc] and self.presentedState[rc].sender then
        -- Jump to the sender's gift
        local sub = self.presentation.submissions[self.currentSub]
        self:setSubmission(self.presentation:findSubIndexByRecipient(sub.sender))
        self.currentItem = 1
        self:updateImageViewer()
    end
end

function Presenter:update(dt)
    -- if self.theme.spec.bgMode ~= "fill" then
    --     self.bg.offsetX = self.bg.offsetX - 48 * dt
    --     self.bg.offsetY = self.bg.offsetY + 24 * dt

    --     self.bg.offsetX = math.fmod(self.bg.offsetX, self.bg.canvas:getWidth())
    --     self.bg.offsetY = math.fmod(self.bg.offsetY, self.bg.canvas:getHeight())
    -- end
end

function Presenter:draw()
    self.bg:draw()
    self.imageViewer:draw()

    self.layout:draw()

    -- Draw sender and recipient
    local rc = self.presentation.submissions[self.currentSub].recipient
    if self.presentedState[rc] then
        local w, h = love.graphics.getDimensions()
        if self.presentedState[rc].recipient then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(senderFontA)
            love.graphics.print("RECIPIENT",
                50,
                h - 50 - senderFontB:getHeight() - senderFontA:getHeight())
            local name = self.presentation.submissions[self.currentSub].recipient
            local sp = self.theme.spec.participants[name]
            if sp and sp.fancyName ~= "" then
                name = self.theme.spec.participants[name].fancyName
            end
            love.graphics.setFont(senderFontB)
            love.graphics.print(name,
                50,
                h - 50 - senderFontB:getHeight()
            )
        end
        if self.presentedState[rc].sender then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(senderFontA)
            love.graphics.print("SENDER",
                w - 50 - senderFontA:getWidth("SENDER"),
                h - 50 - senderFontB:getHeight() - senderFontA:getHeight())
            local name = self.presentation.submissions[self.currentSub].sender
            local sp = self.theme.spec.participants[name]
            if sp and sp.fancyName ~= "" then
                name = self.theme.spec.participants[name].fancyName
            end
            love.graphics.setFont(senderFontB)
            love.graphics.print(name,
                w - 50 - senderFontB:getWidth(name),
                h - 50 - senderFontB:getHeight()
            )
        end
    end

    self.layout:drawDebugRects()
end

function Presenter:drawLeftPanel(rect)
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, rect.w, rect.h)
    love.graphics.translate(5, 5)
    love.graphics.setScissor(15, 15, rect.w - 10, rect.h - 10)
    love.graphics.setFont(presenterFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(0,
        self.scroll * (rect.h - 10 - #self.presentation.submissions * presenterFont:getHeight()))
    for i, sub in ipairs(self.presentation.submissions) do
        local rc = sub.recipient
        if i == self.currentSub then
            love.graphics.setColor(0.5, 0.5, 1, 0.50)
            love.graphics.rectangle("fill", 0, 0, rect.w - 10, presenterFont:getHeight())
        elseif i == self.hover then
            love.graphics.setColor(1, 1, 1, 0.50)
            love.graphics.rectangle("fill", 0, 0, rect.w - 10, presenterFont:getHeight())
        end
        local name = rc
        local sp = self.theme.spec.participants[rc]
        if sp and sp.fancyName ~= "" then
            name = self.theme.spec.participants[name].fancyName
        end
        if not self.presentedState[rc] then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.print(name)

        if self.presentedState[rc] and self.presentedState[rc].recipient then
            love.graphics.setColor(recvColor)
            love.graphics.circle("fill", rect.w - 40, (presenterFont:getHeight()) / 2, 10)
        end

        local thisPersonsSub = self.presentation:findSubBySender(rc)
        if
            self.presentedState[thisPersonsSub.recipient] and
            self.presentedState[thisPersonsSub.recipient].sender then
            love.graphics.setColor(sentColor)
            love.graphics.circle("fill", rect.w - 60, (presenterFont:getHeight()) / 2, 10)
        end

        love.graphics.translate(0, presenterFont:getHeight())
    end
    love.graphics.pop()
end

return Presenter
