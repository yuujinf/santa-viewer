-- Converts the given string in hexadecimal characters to a color table.
-- If the string is 6 characters long, then the color is assumed to be in
-- RRGGBB format with an alpha of 1.0
-- If the string is 8 characters long, then the color is assumed to be in
-- RRGGBBAA format.
local function colorFromHex(s)
    s = "0x" .. s
    local n = tonumber(s)
    if string.len(s) == 8 then
        -- Lua does not have a native integer type so I have to do this nastiness
        local r, g, b = love.math.colorFromBytes(
            math.floor(n / (256 * 256)) % 256,
            math.floor(n / 256) % 256,
            n % 256
        )
        return { r, g, b }
    elseif string.len(s) == 10 then
        local r, g, b, a = love.math.colorFromBytes(
            math.floor(n / (256 * 256 * 256)) % 256,
            math.floor(n / (256 * 256)) % 256,
            math.floor(n / 256) % 256,
            n % 256
        )
        return { r, g, b, a }
    end
end

return colorFromHex
