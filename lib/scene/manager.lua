local Scene = require("lib.scene.scene")
local SceneManager = {}

-- A SceneManager defers all incoming input events and draw calls to its scene.
-- A Scene can access its own manager through the getManager() function, through
-- which scenes can do things like change other scenes.
-- The SceneManager can also handle global events that scenes can emit through
-- their sendEvent() function.
function SceneManager:new(initialScene, params)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o:setScene(initialScene, params)

    return o
end

function SceneManager:setScene(s, params)
    if self.scene then
        self.scene:onSceneClosed()
    end

    s = s or Scene:new()
    s.getManager = function() return self end
    s.sendEvent = function(eventName, p)
        self:handleEvent(eventName, p)
    end

    local p = params or {}
    print("params", p, p.projectName)
    s:initialize(p)
    self.scene = s
end

function SceneManager:mousemoved(x, y, dx, dy, istouch)
    self.scene:mousemoved(x, y, dx, dy, istouch)
end

function SceneManager:mousepressed(x, y, button, istouch, presses)
    self.scene:mousepressed(x, y, button, istouch, presses)
end

function SceneManager:mousereleased(x, y, button, istouch, presses)
    self.scene:mousereleased(x, y, button, istouch, presses)
end

function SceneManager:keypressed(key, scancode, isrepeat)
    self.scene:keypressed(key, scancode, isrepeat)
end

function SceneManager:wheelmoved(dx, dy)
    self.scene:wheelmoved(dx, dy)
end

function SceneManager:update(dt)
    self.scene:update(dt)
end

function SceneManager:draw()
    self.scene:draw()
end

function SceneManager:addHandler(eventName, f)
    self.handlers = self.handlers or {}
    self.handlers[eventName] = f
end

function SceneManager:handleEvent(eventName, payload)
    local h = self.handlers[eventName]
    if h then
        h(self, payload)
    end
end

return SceneManager
