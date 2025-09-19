local Layout = require("lib.layout")

local ImageViewer = {}

function ImageViewer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function ImageViewer:initialize()
    self.image = self.image or love.graphics.newImage(self.filename)
end

function ImageViewer:rebuildLayout(builder)
    builder = builder or Layout.newBuilder()

    self.layout = builder:with(Layout.newItem {
        backgroundColor = { 1, 1, 1 },
        sizing = {
            height = Layout.growSizing(0),
            width = Layout.growSizing(0),
        },
    })
end

function ImageViewer:draw()
end

return ImageViewer
