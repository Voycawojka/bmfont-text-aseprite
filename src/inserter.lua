local inserter = {}

---@param sprite Sprite
---@param image Image
---@return string?
function inserter.insertIntoSprite(sprite, image)
    local originalLayer = app.activeLayer
    if not originalLayer then return "No active layer" end
    if not originalLayer.isImage then return "Active layeris not an image layer" end
    if not originalLayer.isEditable then return "Current layer is not editable" end

    local frame = app.frame or sprite.frames[1]

    app.transaction("Insert BMFont Text", function()
        local tmpLayer = sprite:newLayer()
        tmpLayer.name = "__bmfont_tmp_layer"
        sprite:newCel(tmpLayer, frame, image, Point(0, 0))

        app.activeLayer = tmpLayer
        sprite.selection = Selection(Rectangle(0, 0, image.width, image.height))
        app.command.Cut()

        app.activeLayer = originalLayer
        sprite:deleteLayer(tmpLayer)
    end)
    -- doesn't work properly inside the transaction
    app.command.Paste()

    return nil
end

return inserter
