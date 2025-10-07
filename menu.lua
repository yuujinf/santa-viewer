local Layout = require("lib.layout")
local Scene = require("lib.scene")

local Menu = Scene.newScene()
local PSM = require("pressettingsmenu")

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
            label = "Presentation",
            onClick = function()
                self.presMenu = PSM:new {
                    onConfirm = function(projectName, themeName)
                        self.sendEvent("toPresent", {
                            projectName = projectName,
                            themeName = themeName,
                        })
                    end
                }
            end
        })
        builder:with(Layout.newButton {
            label = "Edit Theme",
            onClick = function()
                self.sendEvent("toThemeEditor", {
                })
            end
        })
    end)
    self.layout:rebuildLayout()
end

function Menu:mousemoved(x, y, dx, dy, istouch)
    if self.presMenu then
        self.presMenu:mousemoved(x, y, dx, dy, istouch)
    end
    if self.layout:mousemoved(x, y, dx, dy, istouch) then return end
end

function Menu:mousepressed(x, y, button, istouch, presses)
    if self.presMenu then
        self.presMenu:mousepressed(x, y, button, istouch, presses)
    end
    if self.layout:mousepressed(x, y, button, istouch, presses) then return end
end

function Menu:mousereleased(x, y, button, istouch, presses)
    if self.presMenu then
        self.presMenu:mousereleased(x, y, button, istouch, presses)
    end
    if self.layout:mousereleased(x, y, button, istouch, presses) then return end
end

function Menu:keypressed(key, scancode, isrepeat)
    if self.presMenu then
        self.presMenu:keypressed(key, scancode, isrepeat)
    end
    if self.layout:keypressed(key, scancode, isrepeat) then return end
end

function Menu:wheelmoved(dx, dy)
    if self.layout:wheelmoved(dx, dy) then return end
end

function Menu:draw()
    self.layout:draw()
    if self.presMenu then
        self.presMenu:draw()
    end
end

return Menu
