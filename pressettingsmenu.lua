local PresSettingsMenu = {}
local Layout = require("lib.layout")
local colorFromHex = require("lib.colorFromHex")

local listFont = love.graphics.newFont(12)
local confirmColor = colorFromHex("648fff")
local hoverColor = colorFromHex("7f7f7f")

function PresSettingsMenu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function PresSettingsMenu:initialize()
    -- Get a list of all projects and all themes
    self.projects = love.filesystem.getDirectoryItems("projects")
    self.themes = love.filesystem.getDirectoryItems("themes")
    table.sort(self.projects)
    table.sort(self.themes)

    print("projects:")
    for _, v in ipairs(self.projects) do
        print(v)
    end
    print("")
    print("themes:")
    for _, v in ipairs(self.themes) do
        print(v)
    end
    print("")

    self.projListState = {}
    self.themeListState = {}

    self.onConfirm = self.onConfirm or function(projectName, themeName) end

    self:rebuildLayout()
end

function PresSettingsMenu:rebuildLayout()
    self.screenW, self.screenH = love.graphics.getDimensions()
    local builder = Layout.newBuilder()
    self.layout = builder:withItem({
            sizing = Layout.rectSizing(self.screenW, self.screenH),
            alignment = {
                h = "center",
                v = "center",
            },
            backgroundColor = { 0, 0, 0, 0.25 },
        },
        function()
            builder:withItem({
                    sizing = {
                        width = Layout.percentSizing(0.3),
                        height = Layout.percentSizing(0.5),
                    },
                    backgroundColor = { 1, 1, 1 },
                    childGap = 10,
                    direction = "v",
                    padding = Layout.padding(10)
                },
                function()
                    builder:withItem({
                            sizing = { width = "grow", height = "grow" },
                            childGap = 10,
                        },
                        function()
                            self:makeList(builder, self.projects, self.projListState, "Projects")
                            self:makeList(builder, self.themes, self.themeListState, "Themes")
                        end)
                    builder:withItem({
                        sizing = { width = "grow" },
                        backgroundColor = { 0.9, 0.9, 0.9 }
                    }, function()
                        builder:with(Layout.newButton {
                            label = "Start",

                            onClick = function()
                                print(self.projListState.confirm)
                                print(self.themeListState.confirm)
                                if self.projListState.confirm and self.themeListState.confirm then
                                    self.onConfirm(
                                        self.projects[self.projListState.confirm],
                                        self.themes[self.themeListState.confirm]
                                    )
                                end
                            end
                        })
                    end)
                end)
        end)

    self.layout:rebuildLayout()
end

function PresSettingsMenu:makeList(builder, list, state, name)
    builder = builder or Layout.newBuilder()
    state = state or {}

    return builder:withItem({
            sizing = { width = "grow", height = "grow" },
            backgroundColor = { 0.9, 0.9, 0.9 },
            direction = "v",
        },
        function()
            builder:with(Layout.newTextItem {
                content = name
            })
            builder:withItem {
                sizing = { width = "grow", height = "grow" },
                drawer = function(l)
                    love.graphics.push("all")
                    love.graphics.setFont(listFont)
                    for i, v in ipairs(list) do
                        if i == state.confirm then
                            love.graphics.setColor(confirmColor)
                            love.graphics.rectangle("fill", 0, 0, l.rect.w, listFont:getHeight())
                        elseif i == state.hover then
                            love.graphics.setColor(hoverColor)
                            love.graphics.rectangle("fill", 0, 0, l.rect.w, listFont:getHeight())
                        end
                        love.graphics.setColor(0, 0, 0)
                        love.graphics.print(v, 0, 0)
                        love.graphics.translate(0, listFont:getHeight())
                    end
                    love.graphics.pop()
                end,

                mousemoved = function(l, x, y, dx, dy, istouch)
                    x, y = x - l.absRect.x, y - l.absRect.y
                    if x >= 0 and x <= l.absRect.w and y >= 0 and y <= l.absRect.h then
                        state.hover = math.floor(y / listFont:getHeight()) + 1
                    else
                        state.hover = nil
                    end
                end,

                mousepressed = function(l, x, y, button, istouch, presses)
                    if state.hover then
                        state.confirm = state.hover
                        return true
                    end
                end
            }
        end)
end

function PresSettingsMenu:mousemoved(x, y, dx, dy, istouch)
    self.layout:mousemoved(x, y, dx, dy, istouch)
end

function PresSettingsMenu:mousepressed(x, y, button, istouch, presses)
    self.layout:mousepressed(x, y, button, istouch, presses)
end

function PresSettingsMenu:mousereleased(x, y, button, istouch, presses)
    self.layout:mousereleased(x, y, button, istouch, presses)
end

function PresSettingsMenu:keypressed(key, scancode, isrepeat)
    self.layout:keypressed(key, scancode, isrepeat)
end

function PresSettingsMenu:draw()
    self.layout:draw()
end

return PresSettingsMenu
