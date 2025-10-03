local Layout = require("lib.layout")

local Presentation = require("presentation")
local ImageViewer = require("imageviewer")
local Theme = require("theme")
local WB = require("wrappingbackground")

local Presenter = {}

local presenterFont = love.graphics.newFont(24)


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
        self.bg = WB:new({ image = self.theme.bg })
    else
        self.bg = WB:new({ filename = "assets/testBg.png" })
    end

    self.currentSub = 1
    self.currentItem = 1

    self.count = 0
    self.scroll = 0
    self.leftPanelVisible = true

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
    print(mediaFilename)
    self.imageViewer:setImage(mediaFilename)
    self.imageViewer:zoomToFit()
end

function Presenter:nextSubmission()
    self.currentItem = self.currentItem + 1
    if self.currentItem <= self.presentation:numberOfItems(self.currentSub) then return end

    self.currentItem = 1

    self.currentSub = self.currentSub + 1
    if self.currentSub <= self.presentation:numberOfSubmissions() then return end

    self.currentSub = 1

    local newScroll = (self.leftPanelRect.height - presenterFont:getHeight()) / 2
        - presenterFont:getHeight() * (self.currentSub - 1)

    self.scroll = newScroll / (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight())
    self.scroll = math.max(0, math.min(1, self.scroll))
end

function Presenter:prevSubmission()
    self.currentItem = self.currentItem - 1
    if self.currentItem >= 1 then return end

    self.currentSub = self.currentSub - 1
    if self.currentSub >= 1 then
        self.currentItem = self.presentation:numberOfItems(self.currentSub)
        return
    end

    self.currentSub = self.presentation:numberOfSubmissions()
    self.currentItem = self.presentation:numberOfItems(self.currentSub)
end

function Presenter:mousemoved(x, y, dx, dy, istouch)
    self.imageViewer:mousemoved(x, y, dx, dy, istouch)

    if self.leftPanelVisible then
        local rx, ry = x - (self.leftPanelRect.x + 5),
            y - (self.leftPanelRect.y + 5) -
            (self.scroll * (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight()))
        print(rx, math.floor(ry / presenterFont:getHeight()) + 1)

        if rx >= 0 and rx <= self.leftPanelRect.w then
            self.hover = math.floor(ry / presenterFont:getHeight()) + 1
        else
            self.hover = nil
        end
    end
end

function Presenter:mousepressed(x, y, button, istouch, presses)
    if self.hover and self.leftPanelVisible then
        self.currentSub = self.hover
        self.currentItem = 1

        local newScroll = (self.leftPanelRect.h - presenterFont:getHeight()) / 2
            - presenterFont:getHeight() * (self.currentSub - 1)

        self.scroll = newScroll /
            (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight())
        self.scroll = math.max(0, math.min(1, self.scroll))
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
    print(self.scroll)
end

function Presenter:scrollItemPosition(i)
    local y = self.scroll * (self.leftPanelRect.h - 10 - #self.presentation.participants * presenterFont:getHeight())
    y = y + (i - 1) * presenterFont:getHeight()
    return y
end

function Presenter:keypressed(key, scancode, isrepeat)
    if key == "right" then
        self:nextSubmission()
        self:updateImageViewer()
    elseif key == "left" then
        self:prevSubmission()
        self:updateImageViewer()
    elseif scancode == "0" then
        self.imageViewer:zoomToFit()
    elseif key == "tab" then
        self.leftPanelVisible = not self.leftPanelVisible
    end
end

function Presenter:update(dt)
    self.bg.offsetX = self.bg.offsetX - 48 * dt
    self.bg.offsetY = self.bg.offsetY + 24 * dt

    self.bg.offsetX = math.fmod(self.bg.offsetX, self.bg.canvas:getWidth())
    self.bg.offsetY = math.fmod(self.bg.offsetY, self.bg.canvas:getHeight())
end

function Presenter:draw()
    self.bg:draw()
    self.imageViewer:draw()

    self.layout:draw()
end

function Presenter:drawLeftPanel(rect)
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.translate(5, 5)
    love.graphics.setScissor(15, 15, rect.w - 10, rect.h - 10)
    love.graphics.setFont(presenterFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(0,
        self.scroll * (rect.h - 10 - #self.presentation.participants * presenterFont:getHeight()))
    for i, rc in ipairs(self.presentation.participants) do
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
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(name)
        love.graphics.translate(0, presenterFont:getHeight())
    end
    love.graphics.pop()
end

return Presenter
