local Theme = {}

local json = require("lib.json")

function Theme:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function Theme:initialize()
    if self.themeName then self:loadTheme(self.themeName) end
end

function Theme:loadTheme(name)
    local path = "themes/" .. name

    self.avatars = {}
    self.bg = love.graphics.newImage(path .. "/" .. "bg.png") or nil

    local avDir = love.filesystem.getDirectoryItems(path .. "/" .. "avatars")
    for _, a in ipairs(avDir) do
        local newAv = love.graphics.newImage(avDir .. "/" .. a)
        if newAv then
            local basename = string.match(a, "(.+)-.+")
            print(basename)
            self.avatars[basename] = newAv
        end
    end

    local data = love.filesystem.read(path .. "/" .. "spec.json")
    self.spec = json.decode(data)
end

function Theme.load(name)
    return Theme:new({ themeName = name })
end

return Theme
