local renderer = {}

---@param fnt FntSpec
---@param codepoints integer[]
---@return integer
local function calculateLineWidth(fnt, codepoints)
    local width = 0
    ---@type integer
    local prev = nil

    for i = 1, #codepoints do
        local current = codepoints[i]
        local char = fnt.chars[current]

        if char then
            if prev and fnt.kernings[prev] then
                local kerning = fnt.kernings[prev][current]
                width = width + (kerning or 0)
            end

            width = width + char.xadvance
            prev = current
        end
    end

    local lastChar = fnt.chars[codepoints[#codepoints]]
    local rightWidth = lastChar.xoffset + lastChar.width - lastChar.xadvance
    if rightWidth > 0 then
        width = width + rightWidth
    end

    return width
end

---@param fnt FntSpec
---@param text string
---@return string[], integer
local function parseLines(fnt, text)
    local lines = {}
    local maxLineWidth = 1
    for line in (text .. "\\n"):gmatch("(.-)\\n") do
        local codepoints = { utf8.codepoint(line, 1, -1) }
        lines[#lines + 1] = codepoints

        local lineWidth = calculateLineWidth(fnt, codepoints)
        if lineWidth > maxLineWidth then
            maxLineWidth = lineWidth
        end
    end
    return lines, maxLineWidth
end

---@param fnt FntSpec
---@param pages Image[]
---@param text string
---@return Image?, string?
function renderer.renderText(fnt, pages, text)
    local lines, maxLineWidth = parseLines(fnt, text)

    local lineHeight = fnt.common.lineHeight
    local totalHeight = math.max(1, #lines * lineHeight)
    local targetImage = Image(maxLineWidth, totalHeight, ColorMode.RGB)

    ---@type {[integer]: Image}
    local glyphCache = {}

    for lineIndex, line in ipairs(lines) do
        local cx = 0
        local cy = (lineIndex - 1) * lineHeight
        ---@type string?
        local prev = nil

        for i = 1, #line do
            local current = line[i]
            local char = fnt.chars[current]

            if char then
                if prev and fnt.kernings[prev] then
                    local kerning = fnt.kernings[prev][current]
                    cx = cx + (kerning or 0)
                end

                if char.page >= 0 and char.width > 0 and char.height > 0 then
                    local page = pages[char.page]

                    if page then
                        local glyph = glyphCache[current] or Image(page, Rectangle(char.x, char.y, char.width, char.height))
                        glyphCache[current] = glyph

                        targetImage:drawImage(glyph, Point(cx + char.xoffset, cy + char.yoffset))
                    end
                end

                cx = cx + char.xadvance
                prev = current
            end
        end
    end

    return targetImage
end

return renderer
