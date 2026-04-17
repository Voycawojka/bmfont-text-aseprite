local fntLoader = require "src.fnt-loader"
local renderer = require "src.renderer"
local inserter = require "src.inserter"

---@class PluginState
---@field loadedFnt FntSpec?
---@field loadedPages Image[]?

---@type PluginState
local state = {
    loadedFnt = nil,
    loadedPages = nil,
}

local dialog = Dialog("Insert BMFont Text") --[[@as Dialog]]

local function onFntPicked()
    local fntPath = dialog.data.fontspec --[[@as string?]]
    if not fntPath or fntPath == "" then return end

    local err
    state.loadedFnt, state.loadedPages, err = fntLoader.loadPath(fntPath)
    if not state.loadedFnt or not state.loadedPages then
        app.alert("Error: " .. err)
        return
    end
end

local function onInsertClicked()
    if not app.sprite then
        app.alert("Open or create a sprite first")
        return
    end

    if not state.loadedFnt or not state.loadedPages then
        app.alert("Choose a font first")
        return
    end

    local text = dialog.data.text --[[@as string?]]
    if not text or text == "" then
        app.alert("Enter some text to insert")
        return
    end

    local image, err = renderer.renderText(state.loadedFnt, state.loadedPages, text)
    if not image then
        app.alert("Error: " .. err)
        return
    end

    err = inserter.insertIntoSprite(app.sprite, image)
    if err then
        app.alert("Error: " .. err)
        return
    end

    dialog:close()
end

dialog:entry {
    id = "text",
    label = "Text:",
    text = "",
}
dialog:file {
    id = "fontspec",
    label = "Font file:",
    title = "Pick a .fnt file",
    filename = "",
    basepath = "",
    open = true,
    save = false,
    entry = false,
    filetypes = { "fnt" },
    onchange = onFntPicked,
}
dialog:separator{}
dialog:button {
    id = "insert",
    text = "Insert",
    onclick = onInsertClicked,
}
dialog:button {
    id = "cancel",
    text = "Cancel",
    onclick = function() dialog:close() end,
}

return dialog
