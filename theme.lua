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
    self.main = love.graphics.newImage(path .. "/" .. "participants.png") or nil

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

    for k, v in pairs(self.spec.participants) do
        v.xPos = v.xPos or 0
        v.yPos = v.yPos or 0
        v.radius = v.radius or 10
        v.fancyName = v.fancyName or ""
    end

    print(self.spec.bgMode)
end

function Theme:save(destination)
    local path = "themes/" .. destination .. "/spec.json"
    print("saving to", path)
    local data = json.encode(self.spec)
    print(data)
end

function Theme.load(name)
    return Theme:new({ themeName = name })
end

return Theme
