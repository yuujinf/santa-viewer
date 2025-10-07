local Scene = require("lib.scene")
local Presenter = require("presenter")

local PresenterScene = Scene.newScene()

function PresenterScene:initialize(params)
    print(params.projectName)
    print(params.themeName)
    self.presenter = Presenter:new {
        projectName = params.projectName,
        themeName = params.themeName,
    }
end

function PresenterScene:mousemoved(x, y, dx, dy, istouch)
    if self.presenter:mousemoved(x, y, dx, dy, istouch) then return end
end

function PresenterScene:mousepressed(x, y, button, istouch, presses)
    if self.presenter:mousepressed(x, y, button, istouch, presses) then return end
end

function PresenterScene:mousereleased(x, y, button, istouch, presses)
    if self.presenter:mousereleased(x, y, button, istouch, presses) then return end
end

function PresenterScene:keypressed(key, scancode, isrepeat)
    if self.presenter:keypressed(key, scancode, isrepeat) then return end
end

function PresenterScene:wheelmoved(dx, dy)
    if self.presenter:wheelmoved(dx, dy) then return end
end

function PresenterScene:draw()
    self.presenter:draw()
end

return PresenterScene
