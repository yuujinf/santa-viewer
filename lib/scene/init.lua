local SceneManager = require("lib.scene.manager")
local SceneType = require("lib.scene.scene")
local Scene = {}

-- Constructs a new SceneManager.
function Scene.newManager(initialScene, params)
    return SceneManager:new(initialScene, params)
end

-- Constructs a new Scene.
function Scene.newScene(o)
    return SceneType:new(o)
end

return Scene
