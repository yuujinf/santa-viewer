local Scene = {}

-- A Scene is an individual gameplay scene with its own initialization,
-- update, and draw commands.
function Scene:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function Scene:initialize(params)
end

function Scene:onSceneClosed()
end

function Scene:mousemoved(x, y, dx, dy, istouch)
end

function Scene:mousepressed(x, y, button, istouch, presses)
end

function Scene:mousereleased(x, y, button, istouch, presses)
end

function Scene:keypressed(key, scancode, isrepeat)
end

function Scene:wheelmoved(dx, dy)
end

function Scene:update(dt)
end

function Scene:draw()
end

return Scene
