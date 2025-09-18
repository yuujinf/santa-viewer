local Scene = require("lib.scene")
local Menu = require("menu")

local wrapIm = love.graphics.newImage("assets/testIm.jpg")
wrapIm:setWrap("repeat", "repeat", "repeat")
-- wrapIm:setFilter("nearest", "nearest", 0)

local testCanvas = love.graphics.newCanvas(wrapIm:getDimensions())
testCanvas:setWrap("repeat", "repeat", "repeat")
-- testCanvas:setFilter("nearest", "nearest", 0)

local state = {
    scene = nil,

    dragging = false,
    mouseOriginX = 0,
    mouseOriginY = 0,
    offsetX = 0,
    offsetY = 0,
    curOffsetX = 0,
    curOffsetY = 0,

    scaleLevel = 0,
    scaleFactor = 1,
}

function love.load()
    state.scene = Scene.newManager(Menu, {})

    state.shader = love.graphics.newShader([[
        uniform Image wrapIm;
        uniform vec2 canvasDims;
        uniform vec2 offset;
        uniform vec2 currentOffset;
        uniform float zoom;

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            vec2 uv = ((screen_coords/zoom - offset -currentOffset-love_ScreenSize.xy/2)/canvasDims-0.5);
            vec4 texturecolor = Texel(wrapIm, uv);
            return texturecolor * color;
        }
    ]])
    state.shader:send("canvasDims", { testCanvas:getDimensions() })
    state.shader:send("offset", { 0, 0 })
    state.shader:send("currentOffset", { 0, 0 })
    state.shader:send("zoom", 1)
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- state.scene:mousemoved(x, y, dx, dy, istouch)
    if state.dragging and love.mouse.isDown(1) then
        state.curOffsetX, state.curOffsetY = x - state.mouseOriginX, y - state.mouseOriginY
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- state.scene:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        state.dragging = true
        state.mouseOriginX = x
        state.mouseOriginY = y
        state.curOffsetX = 0
        state.curOffsetY = 0
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    -- state.scene:mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        state.dragging = false
        state.offsetX = state.offsetX + state.curOffsetX
        state.offsetY = state.offsetY + state.curOffsetY
        state.curOffsetX = 0
        state.curOffsetY = 0
    end
end

function love.keypressed(key, scancode, isrepeat)
    -- state.scene:keypressed(key, scancode, isrepeat)
end

function love.wheelmoved(dx, dy)
    if dy < 0 then
        state.scaleLevel = state.scaleLevel - 1
    elseif dy > 0 then
        state.scaleLevel = state.scaleLevel + 1
    end
    state.scaleFactor = math.pow(math.sqrt(2), state.scaleLevel)
    state.shader:send("zoom", state.scaleFactor)
end

function love.update(dt)
    -- state.scene:update(dt)
end

function love.draw()
    love.graphics.setCanvas(testCanvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(10)
    love.graphics.draw(wrapIm, 0, 0)
    love.graphics.setCanvas()
    state.shader:send("wrapIm", testCanvas)
    state.shader:send("offset", { state.offsetX, state.offsetY })
    state.shader:send("currentOffset", { state.curOffsetX, state.curOffsetY })
    love.graphics.setShader(state.shader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setShader()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(string.format("offset %d %d", state.offsetX, state.offsetY))
    love.graphics.push()
    love.graphics.translate(0, 20)
    local mx, my = love.mouse.getPosition()
    local px, py =
        math.fmod(mx - state.offsetX + testCanvas:getWidth() / 2 - love.graphics.getWidth() / 2, testCanvas:getWidth()),
        math.fmod(my - state.offsetY + testCanvas:getHeight() / 2 - love.graphics.getHeight() / 2, testCanvas:getHeight())
    if px < 0 then px = px + testCanvas:getWidth() end
    if py < 0 then py = py + testCanvas:getHeight() end
    love.graphics.print(string.format("mouse %d %d", px, py))
    love.graphics.pop()
end
