local LayoutOptions = {}

-- Occupy exactly this many pixels along the given axis.
-- Using a literal number in place of this is equivalent to fixed sizing with this parameter.
function LayoutOptions.fixedSizing(value)
    return { "fit", value, value }
end

-- Start at an optional min size and grow by exactly enough to contain all children, up to
-- an optional maximum size.
-- Using the literal string "fit" in place of this is equivalent to a fit with no min or max size.
function LayoutOptions.fitSizing(min, max)
    if min and max and max < min then error("max cannot be less than min") end
    return { "fit", min, max }
end

-- Start at an optional min size and grow to fill all available space in the parent container,
-- up to an optional maximum size.
-- Using the literal string "grow" in place of this is equivalent to a grow with no min or max size.
function LayoutOptions.growSizing(min, max)
    if min and max and max < min then error("max cannot be less than min") end
    return { "grow", min, max }
end

-- Occupy this percentage of space in the parent container.
function LayoutOptions.percentSizing(p)
    return { "percent", p }
end

-- Use this in place of the 'sizing' parameter to create fixed sizing with these bounds.
function LayoutOptions.rectSizing(w, h)
    return {
        width = w,
        height = h,
    }
end

-- Describes the amount of padding in the inside of this container.
-- 1 argument: padding to all 4 sides
-- 2 arguments: first argument is top/bottom padding, second argument is left/right padding
-- 4 arguments: arguments describe top, bottom, left and right padding in that order
function LayoutOptions.padding(...)
    local n = select('#', ...)
    if n == 1 then
        local p = select(1, ...)
        return {
            top = p,
            bottom = p,
            left = p,
            right = p
        }
    elseif n == 2 then
        local tb, lr = select(1, ...)
        return {
            top = tb,
            bottom = tb,
            left = lr,
            right = lr
        }
    else
        local t, b, l, r = select(1, ...)
        return {
            top = t,
            bottom = b,
            left = l,
            right = r,
        }
    end
end

-- Describes options for floating objects. The anchor determines where the floating
-- object would be placed relative to its container.
function LayoutOptions.float(o)
    o = o or {}
    o.anchor = o.anchor or {
        h = "begin",
        v = "begin",
    }
    o.anchor.h = o.anchor.h or "begin"
    o.anchor.v = o.anchor.v or "begin"
    o.x = o.x or 0
    o.y = o.y or 0
    o.z = o.z or 1

    return o
end

-- Describes the color of the border on each side of the container.
-- 1 argument: border on all 4 sides
-- 2 arguments: first argument is top/bottom border, second argument is left/right border
-- 4 arguments: arguments describe top, bottom, left and right border in that order
function LayoutOptions.border(...)
    local n = select('#', ...)
    if n == 1 then
        local c = select(1, ...)
        return {
            top = c,
            bottom = c,
            left = c,
            right = c,
        }
    elseif n == 2 then
        local tb, lr = select(1, ...)
        return {
            top = tb,
            bottom = tb,
            left = lr,
            right = lr
        }
    else
        local t, b, l, r = select(1, ...)
        return {
            top = t,
            bottom = b,
            left = l,
            right = r
        }
    end
end

return LayoutOptions
