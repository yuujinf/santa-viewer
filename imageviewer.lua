local Layout = require("lib.layout")

local ImageViewer = {}

local FIT_MARGIN = 20

function ImageViewer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function ImageViewer:initialize()
    if self.filename then self:setImage(self.filename) end

    self.offsetX = 0
    self.offsetY = 0

    self.dragging = false
    self.mouseOriginX = 0
    self.mouseOriginY = 0
    self.curOffsetX = 0
    self.curOffsetY = 0

    self.scaleLevel = 0
    self.scaleFactor = 1

    self.hide = false
end

function ImageViewer:setImage(filename)
    self.image = love.graphics.newImage(filename)
    self.image:setFilter("linear", "linear", 0)

    self.offsetX = 0
    self.offsetY = 0

    self.dragging = false
    self.mouseOriginX = 0
    self.mouseOriginY = 0
    self.curOffsetX = 0
    self.curOffsetY = 0

    self.scaleLevel = 0
    self.scaleFactor = 1
    self.zoomMode = "normal"
end

function ImageViewer:clearImage()
    self.image = nil
end

function ImageViewer:draw()
    if not self.image then return end
    local sw, sh = love.graphics.getDimensions()
    love.graphics.push()
    love.graphics.translate(
        math.floor(sw / 2 + self.offsetX + self.curOffsetX),
        math.floor(sh / 2 + self.offsetY + self.curOffsetY)
    )
    love.graphics.scale(self.scaleFactor)
    love.graphics.translate(math.floor(-self.image:getWidth() / 2), math.floor(-self.image:getHeight() / 2))

    -- Draw background rectangle
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.rectangle("fill", -10, -10, self.image:getWidth() + 20, self.image:getHeight() + 20)
    if self.hide then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, 0, self.image:getDimensions())
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.image, 0, 0)
    end
    love.graphics.pop()
end

function ImageViewer:mousemoved(x, y, dx, dy, istouch)
    if not self.image then return end
    if self.dragging and love.mouse.isDown(1) then
        self.curOffsetX, self.curOffsetY = x - self.mouseOriginX, y - self.mouseOriginY
    end
end

function ImageViewer:mousepressed(x, y, button, istouch, presses)
    if not self.image then return end
    if button == 1 then
        self.dragging = true
        self.mouseOriginX = x
        self.mouseOriginY = y
        self.curOffsetX = 0
        self.curOffsetY = 0
    end
end

function ImageViewer:mousereleased(x, y, button, istouch, presses)
    if not self.image then return end
    if button == 1 then
        self.dragging = false
        self.offsetX = self.offsetX + self.curOffsetX
        self.offsetY = self.offsetY + self.curOffsetY
        self.curOffsetX = 0
        self.curOffsetY = 0
    end
end

function ImageViewer:wheelmoved(dx, dy)
    if not self.image then return end
    local oldLevel, oldFactor = self.scaleLevel, self.scaleFactor
    if self.zoomMode == "fit" then
        if dy < 0 then
            self.scaleLevel = math.floor(math.log(self.scaleFactor, 2))
        elseif dy > 0 then
            self.scaleLevel = math.ceil(math.log(self.scaleFactor, 2))
        else
            return
        end
        self.scaleFactor = 2 ^ self.scaleLevel
        self.zoomMode = "normal"

        self.scaleFactor = 2 ^ self.scaleLevel

        local delta = self.scaleFactor / oldFactor

        -- Adjust the offset position based on zoom
        local mx, my = love.mouse.getPosition()
        local sx, sy = love.graphics.getDimensions()
        mx, my = mx - sx / 2, my - sy / 2

        local ddx, ddy = (self.offsetX - mx), (self.offsetY - my)
        self.offsetX = self.offsetX + ddx * (delta - 1)
        self.offsetY = self.offsetY + ddy * (delta - 1)

        return
    end
    if dy < 0 then
        self.scaleLevel = self.scaleLevel - 1
    elseif dy > 0 then
        self.scaleLevel = self.scaleLevel + 1
    end

    if oldLevel == oldFactor then return end

    self.scaleFactor = 2 ^ self.scaleLevel

    local delta = self.scaleFactor / oldFactor

    -- Adjust the offset position based on zoom
    local mx, my = love.mouse.getPosition()
    local sx, sy = love.graphics.getDimensions()
    mx, my = mx - sx / 2, my - sy / 2

    local ddx, ddy = (self.offsetX - mx), (self.offsetY - my)
    self.offsetX = self.offsetX + ddx * (delta - 1)
    self.offsetY = self.offsetY + ddy * (delta - 1)
end

function ImageViewer:zoomToFit()
    self.offsetX = 0
    self.offsetY = 0

    self.dragging = false
    self.mouseOriginX = 0
    self.mouseOriginY = 0
    self.curOffsetX = 0
    self.curOffsetY = 0

    local sw, sh = love.graphics.getDimensions()
    self.scaleFactor = math.min(
        (sw - FIT_MARGIN * 2) / self.image:getWidth(),
        (sh - FIT_MARGIN * 2) / self.image:getHeight()
    )

    self.zoomMode = "fit"
end

return ImageViewer
