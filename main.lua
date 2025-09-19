local Layout = require("lib.layout")
local Scene = require("lib.scene")
local Menu = require("menu")

local WB = require("wrappingbackground")
local IV = require("imageviewer")

love.graphics.setDefaultFilter("nearest", "nearest")

local state = {
    scene = nil,

    bg = WB:new({ filename = "assets/testIm.png" }),

    viewer = IV:new({ filename = "assets/testIm.png" }),
}

function love.load()
    state.scene = Scene.newManager(Menu, {})
    state:rebuildLayout()
end

function state:rebuildLayout()
    self.screenW, self.screenH = love.graphics.getDimensions()
    local b = Layout.newBuilder()
    self.layout = b:with(Layout.newItem {
            sizing = Layout.rectSizing(self.screenW, self.screenH),
            padding = Layout.padding(10),
            childGap = 10,
        },
        function()
            b:with(Layout.newItem { sizing = { width = 300 } })
            self.viewer:rebuildLayout(b)
            b:with(Layout.newItem { sizing = { width = 300 } })
        end)

    self.layout:rebuildLayout()
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- state.scene:mousemoved(x, y, dx, dy, istouch)
    state.bg:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    -- state.scene:mousepressed(x, y, button, istouch, presses)
    state.bg:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    -- state.scene:mousereleased(x, y, button, istouch, presses)
    state.bg:mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
    -- state.scene:keypressed(key, scancode, isrepeat)
    state.bg:keypressed(key, scancode, isrepeat)
end

function love.wheelmoved(dx, dy)
    state.bg:wheelmoved(dx, dy)
end

function love.update(dt)
    -- state.scene:update(dt)
end

function love.draw()
    state.bg:draw()
    state.layout:draw()
end
