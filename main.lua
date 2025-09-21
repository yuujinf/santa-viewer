local Layout = require("lib.layout")
local Scene = require("lib.scene")
local Menu = require("menu")

local WB = require("wrappingbackground")
local IV = require("imageviewer")
local P = require("presenter")

love.graphics.setDefaultFilter("nearest", "nearest")

local state = {
    scene = nil,

    bg = WB:new({ filename = "assets/testBg.png" }),

    presenter = P:new({ projectName = "santa24" })
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
            -- self.viewer:rebuildLayout(b)
        end)

    self.layout:rebuildLayout()
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- state.scene:mousemoved(x, y, dx, dy, istouch)
    -- state.bg:mousemoved(x, y, dx, dy, istouch)
    state.presenter:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    -- state.scene:mousepressed(x, y, button, istouch, presses)
    -- state.bg:mousepressed(x, y, button, istouch, presses)
    state.presenter:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    -- state.scene:mousereleased(x, y, button, istouch, presses)
    -- state.bg:mousereleased(x, y, button, istouch, presses)
    state.presenter:mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
    -- state.scene:keypressed(key, scancode, isrepeat)
    -- state.bg:keypressed(key, scancode, isrepeat)
    state.presenter:keypressed(key, scancode, isrepeat)
end

function love.wheelmoved(dx, dy)
    -- state.bg:wheelmoved(dx, dy)
    state.presenter:wheelmoved(dx, dy)
end

function love.update(dt)
    -- state.scene:update(dt)
    state.bg.offsetX = state.bg.offsetX - 48 * dt
    state.bg.offsetY = state.bg.offsetY + 24 * dt

    state.bg.offsetX = math.fmod(state.bg.offsetX, state.bg.canvas:getWidth())
    state.bg.offsetY = math.fmod(state.bg.offsetY, state.bg.canvas:getHeight())

    state.presenter:update(dt)
end

function love.draw()
    state.bg:draw()
    state.presenter:draw()
    state.layout:draw()
end
