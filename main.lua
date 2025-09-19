local Scene = require("lib.scene")
local Menu = require("menu")
local WB = require("wrappingbackground")

love.graphics.setDefaultFilter("nearest", "nearest")

local state = {
    scene = nil,

    bg = WB:new({ filename = "assets/testIm.png" })
}

function love.load()
    state.scene = Scene.newManager(Menu, {})
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
end
