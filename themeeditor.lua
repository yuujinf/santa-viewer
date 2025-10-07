local Layout = require("lib.layout")
local Scene = require("lib.scene")

local ThemeEditor = Scene.newScene()

local Theme = require("theme")
local WB = require("wrappingbackground")

function ThemeEditor:initialize(params)
    self:loadTheme("defaultTheme2")
    self.theme:save("defaultTheme2")
    self:rebuildLayout()
end

function ThemeEditor:rebuildLayout()
    self.screenW, self.screenH = love.graphics.getDimensions()

    local builder = Layout.newBuilder()
    self.layout = builder:with(Layout.newItem {
        sizing = Layout.rectSizing(self.screenW, self.screenH),
        alignment = {
            h = "center",
            v = "center",
        },
        direction = "v",
    }, function()
    end)
    self.layout:rebuildLayout()
end

function ThemeEditor:loadTheme(themeName)
    self.theme = Theme.load(themeName)

    assert(self.theme.bg, "Must have bg")
    if self.theme.spec.bgMode == "fill" then
        self.bgBack = WB:new({
            image = self.theme.bg,
            mode = self.theme.spec.bgMode,
        })
        self.bg = WB:new({
            image = self.theme.main,
            mode = "wrap",
        })
        self.bg.shader:send("zoom", 0.25)
        self.bg:setWrap(false)
    else
        self.bg = WB:new({
            image = self.theme.main,
            mode = "wrap",
        })
    end

    self.bg:setTint(1)

    self:rebuildLayout()
end

function ThemeEditor:mousemoved(x, y, dx, dy, istouch)
    if self.layout:mousemoved(x, y, dx, dy, istouch) then return end
end

function ThemeEditor:mousepressed(x, y, button, istouch, presses)
    if self.layout:mousepressed(x, y, button, istouch, presses) then return end
end

function ThemeEditor:mousereleased(x, y, button, istouch, presses)
    if self.layout:mousereleased(x, y, button, istouch, presses) then return end
end

function ThemeEditor:keypressed(key, scancode, isrepeat)
    if self.layout:keypressed(key, scancode, isrepeat) then return end
end

function ThemeEditor:wheelmoved(dx, dy)
    if self.layout:wheelmoved(dx, dy) then return end
end

function ThemeEditor:draw()
    if self.theme.spec.bgMode == "fill" then
        self.bgBack:draw()
    end
    self.bg:draw()
    -- self.layout:draw()
end

return ThemeEditor
