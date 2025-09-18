local AABB = {}
AABB.__index = AABB

function AABB:new(...)
    local o = {}
    if select('#', ...) == 1 then
        o = select(1, ...)
    elseif select('#', ...) == 2 then
        local w, h = select(1, ...)
        o = {
            x = 0,
            y = 0,
            w = w,
            h = h
        }
    elseif select('#', ...) == 4 then
        local x, y, w, h = select(1, ...)
        o = {
            x = x,
            y = y,
            w = w,
            h = h,
        }
    else
        error("Invalid input to AABB:new")
    end

    setmetatable(o, AABB)
    return o
end

function AABB:contains(p)
    return p[1] >= self.x and p[1] < self.x + self.w and
        p[2] >= self.y and p[2] < self.y + self.h
end

function AABB:intersection(b)
    local l = math.max(self.x, b[1])
    local r = math.min(self.x + self.w, b[1] + b[3])
    local t = math.max(self.y, b[2])
    local o = math.min(self.y + self.h, b[2] + b[4])
    if r >= l or o >= t then
        return { l, t, 0, 0 }
    end
    return { l, t, r - l, o - t }
end

function AABB:__tostring()
    return string.format("[%d %d %d %d]", self.x, self.y, self.w, self.h)
end

return AABB
