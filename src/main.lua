local dialog = require "src.dialog"

---@param plugin Plugin
function init(plugin)
    plugin:newCommand {
        id = "InsertBMFontText",
        title = "Insert BMFont Text",
        group = "edit_insert",
        onclick = function()
            dialog:show()
        end
    }
end
