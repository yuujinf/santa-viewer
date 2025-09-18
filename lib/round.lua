-- Round to nearest number.
local function round(n)
    return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

return round
