local Layout = require("lib.layout")
local Scene = require("lib.scene")

local Menu = require("menu")
local PresenterScene = require("presenterscene")

love.graphics.setDefaultFilter("nearest", "nearest")

local state = {
    scene = nil,
}

function love.load()
    state.scene = Scene.newManager(Menu, {})

    state.scene:addHandler("toPresent", function(h, params)
        h:setScene(PresenterScene, params)
    end)
end

function love.mousemoved(x, y, dx, dy, istouch)
    state.scene:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    state.scene:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    state.scene:mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
    state.scene:keypressed(key, scancode, isrepeat)
end

function love.wheelmoved(dx, dy)
    state.scene:wheelmoved(dx, dy)
end

function love.update(dt)
    state.scene:update(dt)
end

function love.draw()
    state.scene:draw()
end
