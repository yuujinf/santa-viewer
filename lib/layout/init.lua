local LayoutItem = require("lib.layout.layoutitem")
local LayoutOptions = require("lib.layout.layoutoptions")
local TextItem = require("lib.layout.textitem")
local Button = require("lib.layout.button")
local TabContainer = require("lib.layout.tabcontainer")
local LayoutBuilder = require("lib.layout.layoutbuilder")
local LayoutStack = require("lib.layout.layoutstack")

local Layout = {
    fixedSizing = LayoutOptions.fixedSizing,
    fitSizing = LayoutOptions.fitSizing,
    growSizing = LayoutOptions.growSizing,
    percentSizing = LayoutOptions.percentSizing,
    rectSizing = LayoutOptions.rectSizing,
    padding = LayoutOptions.padding,
    float = LayoutOptions.float,
    border = LayoutOptions.border,
}

function Layout.newItem(options)
    return LayoutItem:new(options)
end

function Layout.newTextItem(options)
    return TextItem:new(options)
end

function Layout.newButton(options)
    return Button:new(options)
end

function Layout.newTabContainer(options)
    return TabContainer:new(options)
end

function Layout.newHSpacer()
    return LayoutItem:new {
        sizing = { width = "grow" }
    }
end

function Layout.newVSpacer()
    return LayoutItem:new {
        sizing = { height = "grow" }
    }
end

function Layout.newBuilder()
    return LayoutBuilder:new()
end

function Layout.newStack()
    return LayoutStack:new()
end

return Layout
