local Layout = require("lib.layout")
local Scene = require("lib.scene")

local Menu = Scene.newScene()

function Menu:initialize(params)
    self:rebuildLayout()
end

function Menu:rebuildLayout()
    self.screenW, self.screenH = love.graphics.getDimensions()

    local builder = Layout.newBuilder()
    self.layout = builder:with(Layout.newItem {
        sizing = Layout.rectSizing(self.screenW, self.screenH),
        alignment = {
            h = "center",
            v = "center",
        },
        direction = "v",
        backgroundColor = { 1, 1, 1 },
    }, function()
        builder:with(Layout.newTextItem {
            content = "Santa Manager",
        })
        builder:with(Layout.newButton {
            label = "Official Presentation",
        })
        builder:with(Layout.newButton {
            label = "Test Presentation",
        })
        builder:with(Layout.newButton {
            label = "Edit Theme",
        })
    end)
    self.layout:rebuildLayout()
end

function Menu:mousemoved(x, y, dx, dy, istouch)
    if self.layout:mousemoved(x, y, dx, dy, istouch) then return end
end

function Menu:mousepressed(x, y, button, istouch, presses)
    if self.layout:mousepressed(x, y, button, istouch, presses) then return end
end

function Menu:mousereleased(x, y, button, istouch, presses)
    if self.layout:mousereleased(x, y, button, istouch, presses) then return end
end

function Menu:keypressed(key, scancode, isrepeat)
    if self.layout:keypressed(key, scancode, isrepeat) then return end
end

function Menu:wheelmoved(dx, dy)
    if self.layout:wheelmoved(dx, dy) then return end
end

function Menu:draw()
    self.layout:draw()
end

return Menu
