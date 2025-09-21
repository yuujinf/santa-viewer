local Presentation = require("presentation")
local ImageViewer = require("imageviewer")

local Presenter = {}

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

    self.currentSub = 1
    self.currentItem = 1

    self.count = 0

    self:updateImageViewer()
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
end

function Presenter:mousepressed(x, y, button, istouch, presses)
    self.imageViewer:mousepressed(x, y, button, istouch, presses)
end

function Presenter:mousereleased(x, y, button, istouch, presses)
    self.imageViewer:mousereleased(x, y, button, istouch, presses)
end

function Presenter:wheelmoved(dx, dy)
    self.imageViewer:wheelmoved(dx, dy)
end

function Presenter:keypressed(key, scancode, isrepeat)
    if key == "right" then
        self:nextSubmission()
        self:updateImageViewer()
    elseif key == "left" then
        self:prevSubmission()
        self:updateImageViewer()
    end
end

function Presenter:update(dt)
    self.count = self.count + 1
    local dirty
    while self.count > 20 do
        self:nextSubmission()
        self.count = self.count - 15
        dirty = true
    end
    if dirty then
        self:updateImageViewer()
    end
end

function Presenter:draw()
    self.imageViewer:draw()
end

return Presenter
